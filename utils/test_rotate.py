"""Disposable-key tests. Run: nix develop .#secrets --command python3 utils/test_rotate.py"""

import importlib.machinery
import importlib.util
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest import mock

loader = importlib.machinery.SourceFileLoader("rotate", str(Path(__file__).with_name("rotate")))
spec = importlib.util.spec_from_loader(loader.name, loader)
rotate = importlib.util.module_from_spec(spec)
loader.exec_module(rotate)


class FixtureRotation(rotate.Rotation):
    def decrypt(self):
        return json.loads(self.secret_file.read_text())

    def encrypt(self, values):
        rotate.atomic_write(self.secret_file, json.dumps(values))


class RotationTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="rotate-test-", dir="/dev/shm")
        self.repo = Path(self.temp.name)
        for directory in ("secrets", "keys/age", "keys/ssh", "keys/nix", "keys/passage"):
            (self.repo / directory).mkdir(parents=True, exist_ok=True)
        for host in rotate.HOSTS:
            (self.repo / f"keys/age/{host}.pub").write_text(f"age1{host}\n")

    def tearDown(self):
        self.temp.cleanup()

    def test_public_key_round_trips(self):
        for kind in rotate.FIELDS:
            private, public = rotate.generate(kind, f"punky-{kind}-test")
            self.assertEqual(rotate.public_for(kind, private), public)

    def test_host_local_ssh_rotation(self):
        old_private, old_public = rotate.generate("ssh", "shared-old")
        secret = self.repo / "secrets/punky.json"
        secret.write_text(json.dumps({"ssh-client": old_private, "unrelated": "keep"}))
        shared = self.repo / "keys/ssh/shared.pub"
        shared.write_text(old_public + "\n")
        rotation = FixtureRotation(self.repo, "punky", "ssh")

        rotation.add()
        values = rotation.decrypt()
        self.assertEqual(values["ssh-client"], old_private)
        self.assertIn("ssh-client-next", values)
        self.assertTrue(rotation.next_public.exists())
        self.assertTrue(shared.exists())

        with mock.patch.object(rotation, "verify_ssh") as verify:
            rotation.apply()
            verify.assert_called_once()
        values = rotation.decrypt()
        self.assertEqual(values["ssh-client-old"], old_private)
        self.assertNotIn("ssh-client-next", values)
        self.assertTrue(rotation.public.exists())
        self.assertFalse(rotation.old_public.exists())

        rotation.retire()
        values = rotation.decrypt()
        self.assertNotIn("ssh-client-old", values)
        self.assertEqual(values["unrelated"], "keep")
        self.assertTrue(shared.exists())

    def test_second_rotation_keeps_old_public_until_retire(self):
        active_private, active_public = rotate.generate("ssh", "punky-active")
        (self.repo / "secrets/punky.json").write_text(json.dumps({"ssh-client": active_private}))
        (self.repo / "keys/ssh/punky.pub").write_text(active_public + "\n")
        rotation = FixtureRotation(self.repo, "punky", "ssh")
        rotation.add()
        with mock.patch.object(rotation, "verify_ssh"):
            rotation.apply()
        self.assertEqual(rotation.old_public.read_text().strip(), active_public)
        rotation.retire()
        self.assertFalse(rotation.old_public.exists())

    def test_passage_migration(self):
        store = self.repo / "password-store"
        store.mkdir()
        (store / ".gpg-id").write_text("test@example.invalid\n")
        (store / ".gitattributes").write_text("*.gpg diff=gpg\n")

        gpg_home = self.repo / "gnupg"
        gpg_home.mkdir(mode=0o700)
        env = dict(os.environ, GNUPGHOME=str(gpg_home))
        rotate.run(["gpg", "--batch", "--passphrase", "", "--quick-generate-key",
                    "test@example.invalid", "rsa2048", "encr", "1d"], env=env)
        plaintext = b"disposable password\n"
        ciphertext = rotate.run(["gpg", "--batch", "--trust-model", "always", "--encrypt",
                                 "--recipient", "test@example.invalid"], plaintext,
                                binary=True, env=env)
        (store / "example.gpg").write_bytes(ciphertext)

        identities = []
        for host in rotate.HOSTS:
            private, public = rotate.generate("passage", host)
            identities.append(private)
            (self.repo / f"keys/passage/{host}.pub").write_text(public + "\n")
        identity_file = self.repo / "identities"
        identity_file.write_text("\n".join(identities))

        real_path = rotate.Path
        def mapped_path(value):
            if str(value) == "/run/secrets/rendered/passage-identities":
                return identity_file
            return real_path(value)

        with mock.patch.object(rotate, "Path", side_effect=mapped_path), \
             mock.patch.dict(os.environ, env):
            rotate.migrate_passage(self.repo, store)

        self.assertFalse((store / "example.gpg").exists())
        self.assertFalse((store / ".gpg-id").exists())
        self.assertEqual(
            rotate.run(["age", "--decrypt", "--identity", identity_file,
                        store / "example.age"], binary=True), plaintext)
        self.assertEqual(len((store / ".age-recipients").read_text().splitlines()), 3)
        self.assertEqual((store / ".gitattributes").read_text(), "*.age diff=age\n")

    def test_source_has_no_git_subprocess(self):
        source = Path(rotate.__file__).read_text()
        self.assertNotIn('run(["git"', source)
        self.assertNotIn('root(["git"', source)


if __name__ == "__main__":
    unittest.main()
