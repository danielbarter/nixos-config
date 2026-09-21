"""Disposable-key tests. Run: nix develop .#secrets --command python3 utils/test_rotate.py"""

import importlib.machinery
import importlib.util
import json
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

    def setup_key(self, kind):
        private, public = rotate.generate(kind, f"punky-{kind}-old")
        (self.repo / "secrets/punky.json").write_text(
            json.dumps({rotate.FIELDS[kind]: private, "unrelated": "preserved"}))
        public_file = self.repo / f"keys/{kind}/punky.pub"
        public_file.write_text(public + "\n")
        return private, public

    def test_public_key_round_trips(self):
        for kind in rotate.FIELDS:
            private, public = rotate.generate(kind, f"punky-{kind}-test")
            self.assertEqual(rotate.public_for(kind, private), public)

    def test_ssh_rotation_replaces_only_this_hosts_key(self):
        old_private, old_public = self.setup_key("ssh")
        rotation = FixtureRotation(self.repo, "punky", "ssh")
        rotation.rotate()
        values = rotation.decrypt()
        self.assertNotEqual(values["ssh-client"], old_private)
        self.assertNotEqual(rotation.public_file.read_text().strip(), old_public)
        self.assertEqual(rotate.public_for("ssh", values["ssh-client"]),
                         rotation.public_file.read_text().strip())
        self.assertEqual(values["unrelated"], "preserved")
        self.assertFalse(list(rotation.public_file.parent.glob("punky-*.pub")))

    def test_rotation_rejects_mismatched_active_key(self):
        self.setup_key("ssh")
        other_private, _ = rotate.generate("ssh", "other")
        (self.repo / "secrets/punky.json").write_text(json.dumps({"ssh-client": other_private}))
        with self.assertRaises(rotate.RotationError):
            FixtureRotation(self.repo, "punky", "ssh").rotate()

    def test_passage_rotation_reencrypts_store(self):
        old_private, old_public = self.setup_key("passage")
        other_private, other_public = rotate.generate("passage", "jasper")
        store = self.repo / "password-store"
        store.mkdir()
        (store / ".age-recipients").write_text(f"{old_public}\n{other_public}\n")
        plaintext = b"disposable password\n"
        (store / "example.age").write_bytes(rotate.run([
            "age", "--encrypt", "--recipient", old_public, "--recipient", other_public
        ], plaintext, binary=True))
        identity_file = self.repo / "identities"
        identity_file.write_text(old_private + other_private)

        real_path = rotate.Path
        def mapped_path(value):
            if str(value) == "/run/secrets/rendered/passage-identities":
                return identity_file
            return real_path(value)

        rotation = FixtureRotation(self.repo, "punky", "passage", store)
        with mock.patch.object(rotate, "Path", side_effect=mapped_path):
            rotation.rotate()

        new_private = rotation.decrypt()["passage-identity"]
        new_public = rotation.public_file.read_text().strip()
        self.assertNotEqual(new_public, old_public)
        self.assertEqual(rotate.public_for("passage", new_private), new_public)
        new_identity = self.repo / "new-identity"
        new_identity.write_text(new_private)
        self.assertEqual(rotate.run([
            "age", "--decrypt", "--identity", new_identity, store / "example.age"
        ], binary=True), plaintext)
        self.assertEqual((store / ".age-recipients").read_text().splitlines(),
                         [new_public, other_public])

    def test_source_has_no_git_subprocess(self):
        source = Path(rotate.__file__).read_text()
        self.assertNotIn('run(["git"', source)
        self.assertNotIn('root(["git"', source)


if __name__ == "__main__":
    unittest.main()
