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
    def decrypt(self, path):
        return json.loads(rotate.run(["sops", "decrypt", path], env=dict(
            os.environ, SOPS_AGE_KEY_FILE=str(self.repo / f"{self.host}.agekey"))))

    def rebuild(self):
        if getattr(self, "fail_rebuild", False):
            raise rotate.RotationError("Simulated failed rebuild")
        self.deployed = self.decrypt(self.secret_file)

    def verify_peers(self, plan, overlap=False):
        self.overlap = overlap
        if getattr(self, "fail_peers", False):
            raise rotate.RotationError("Simulated unreachable host")


class RotationTests(unittest.TestCase):
    def setUp(self):
        os.umask(0o077)
        self.temp = tempfile.TemporaryDirectory(prefix="rotate-test-", dir="/dev/shm")
        self.addCleanup(self.temp.cleanup)
        self.repo = Path(self.temp.name)
        for host in rotate.HOSTS:
            rotate.run(["age-keygen", "-o", self.repo / f"{host}.agekey"])
            public = rotate.run(["age-keygen", "-y", self.repo / f"{host}.agekey"])
            path = self.repo / "keys/age" / f"{host}.pub"
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(public)

    def setup_kind(self, kind):
        old = rotate.generate(kind, "", "old-test-key")
        for host in rotate.HOSTS if kind != "wireguard" else ("blaze",):
            rotation = FixtureRotation(self.repo, host, kind)
            rotation.encrypt(rotation.secret_file, {rotate.FIELDS[kind]: old["private"],
                                                   "unrelated": "preserve-me"}, (host,))
        path = self.repo / "keys" / kind / ("blaze.pub" if kind == "wireguard" else "legacy.pub")
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(old["public"] + " old-comment\n" if kind == "ssh" else old["public"] + "\n")
        return old

    def activate(self, rotation, phase="apply"):
        def root(args, data=None, **options):
            if args[0] == "cat":
                return rotation.deployed[Path(args[1]).name]
            if args[:3] == ["nix", "store", "sign"]:
                return ""
            self.fail(f"Unexpected privileged command: {args}")
        with mock.patch.object(rotate, "root", side_effect=root):
            getattr(rotation, phase)()

    def test_shared_ssh_rotation_and_overlap(self):
        old = self.setup_kind("ssh")
        first = FixtureRotation(self.repo, "punky", "ssh")
        first.add()
        self.activate(first)
        self.assertTrue(first.overlap)
        with self.assertRaises(rotate.RotationError):
            first.retire()
        identity = first.load()["id"]
        for host in ("jasper", "blaze"):
            other = FixtureRotation(self.repo, host, "ssh")
            other.add()
            self.assertEqual(other.load()["id"], identity)
            self.assertEqual(other.decrypt(other.secret_file)["ssh-client"], old["private"])
        payload = first.decrypt(first.pending_file)
        self.assertNotEqual(payload["private"], old["private"])
        for host in rotate.HOSTS:
            rotation = FixtureRotation(self.repo, host, "ssh")
            self.assertEqual(rotation.decrypt(rotation.pending_file), payload)
            self.activate(rotation)
            values = rotation.decrypt(rotation.secret_file)
            self.assertEqual(values["ssh-client"], old["private"])
            self.assertEqual(values["ssh-client-next"], payload["private"])
            self.assertEqual(values["unrelated"], "preserve-me")
            ciphertext = json.loads(rotation.secret_file.read_text())
            self.assertEqual(len(ciphertext["sops"]["age"]), 1)
        self.assertTrue((self.repo / "keys/ssh/legacy.pub").exists())
        for path in self.repo.glob("keys/**/*.json"):
            self.assertNotIn("PRIVATE KEY", path.read_text())
        for host in rotate.HOSTS:
            rotation = FixtureRotation(self.repo, host, "ssh")
            self.activate(rotation, "retire")
            self.assertFalse(rotation.overlap)
            values = rotation.decrypt(rotation.secret_file)
            self.assertEqual(values["ssh-client"], payload["private"])
            self.assertNotIn("ssh-client-next", values)
        self.assertFalse((self.repo / "keys/ssh/legacy.pub").exists())
        self.assertFalse(first.pending_file.exists())
        self.assertTrue(first.load()["finished"])
        first.add()
        self.assertNotEqual(first.load()["id"], identity)

    def test_failure_does_not_record_success_and_apply_can_retry(self):
        self.setup_kind("ssh")
        rotations = [FixtureRotation(self.repo, host, "ssh") for host in rotate.HOSTS]
        for rotation in rotations:
            rotation.add()
        first = rotations[0]
        before = first.secret_file.read_text()
        first.fail_peers = True
        with self.assertRaises(rotate.RotationError):
            self.activate(first)
        self.assertEqual(first.secret_file.read_text(), before)
        first.fail_peers = False
        first.fail_rebuild = True
        with self.assertRaises(rotate.RotationError):
            self.activate(first)
        self.assertNotIn("punky", first.load()["apply"])
        with self.assertRaises(rotate.RotationError):
            first.retire()
        first.fail_rebuild = False
        self.activate(first)
        self.assertIn("punky", first.load()["apply"])

    def test_plaintext_sops_output_is_never_written(self):
        rotation = FixtureRotation(self.repo, "punky", "ssh")
        with mock.patch.object(rotate, "run", return_value=json.dumps({"private": "plaintext", "sops": {}})):
            with self.assertRaises(rotate.RotationError):
                rotation.encrypt(rotation.pending_file, {"private": "plaintext"}, rotate.HOSTS)
        self.assertFalse(rotation.pending_file.exists())

    def test_ssh_checks_both_accounts_with_only_the_new_identity(self):
        rotation = FixtureRotation(self.repo, "punky", "ssh")
        def network(args, data=None, **kwargs):
            if args[0] == "findmnt":
                return "tmpfs\n"
            if args[0] == "ssh":
                self.assertIn("IdentityAgent=none", args)
                self.assertIn("IdentitiesOnly=yes", args)
                self.assertNotIn("/run/secrets/ssh-client", args)
                self.assertEqual(Path(args[args.index("-i") + 1]).read_text(), "new private key")
                return "/nix/store/test-system\n"
            self.assertEqual(args[:3], ["nix", "path-info", "--store"])
            self.assertIn("ssh://nix-ssh@", args[3])
            self.assertIn("IdentityAgent=none", kwargs["env"]["NIX_SSHOPTS"])
            return "/nix/store/test-system\n"
        with mock.patch.object(rotation, "payload", return_value={"private": "new private key"}):
            with mock.patch.object(rotate, "run", side_effect=network) as command:
                rotate.Rotation.verify_peers(rotation, {})
                self.assertEqual(sum(c.args[0][0] == "ssh" for c in command.call_args_list), 3)
                self.assertEqual(sum(c.args[0][0] == "nix" for c in command.call_args_list), 3)

    def test_nix_rotation(self):
        self.setup_kind("nix")
        rotations = [FixtureRotation(self.repo, host, "nix") for host in rotate.HOSTS]
        for rotation in rotations:
            rotation.add()
        for rotation in rotations:
            self.activate(rotation)
            self.assertIn("nix-signing-next", rotation.deployed)
        for rotation in rotations:
            self.activate(rotation, "retire")
            self.assertNotIn("nix-signing-next", rotation.deployed)
        self.assertFalse((self.repo / "keys/nix/legacy.pub").exists())

    def test_wireguard_replaces_blaze_key_and_imports_phone_public_key(self):
        old = self.setup_kind("wireguard")
        with self.assertRaises(rotate.RotationError):
            FixtureRotation(self.repo, "punky", "wireguard")
        rotation = FixtureRotation(self.repo, "blaze", "wireguard")
        phone = rotate.generate("wireguard", "", "phone")["public"]
        phone_file = self.repo / "phone.pub"
        phone_file.write_text(phone + "\n")
        rotation.replace_wireguard(phone_file)
        values = rotation.decrypt(rotation.secret_file)
        self.assertNotEqual(values["wireguard"], old["private"])
        self.assertEqual(values["unrelated"], "preserve-me")
        self.assertEqual((self.repo / "keys/wireguard/blaze.pub").read_text().strip(),
                         rotate.public_for("wireguard", values["wireguard"]))
        self.assertEqual((self.repo / "keys/wireguard/phone.pub").read_text().strip(), phone)
        self.assertFalse(rotation.manifest_file.exists())
        self.assertFalse(rotation.pending_file.exists())

    def test_gpg_adds_subkey_without_losing_old_keys(self):
        with rotate.keyring([]) as env:
            rotate.run(["gpg", "--batch", "--pinentry-mode", "loopback", "--passphrase", "",
                        "--quick-generate-key", "Rotation Test <test@example.invalid>", "ed25519", "cert", "1y"], env=env)
            primary, _ = rotate.fingerprints(env)
            rotate.run(["gpg", "--batch", "--pinentry-mode", "loopback", "--passphrase", "",
                        "--quick-add-key", primary[0], "cv25519", "encr", "1y"], env=env)
            _, before = rotate.fingerprints(env)
            old = rotate.run(["gpg", "--armor", "--export-secret-keys"], env=env)
        with mock.patch.object(rotate.getpass, "getpass", return_value=""):
            payload = rotate.generate("gpg", old, "test")
        with rotate.keyring([payload["private"]]) as env:
            after_primary, after = rotate.fingerprints(env)
            self.assertEqual(after_primary, primary)
            self.assertTrue(set(before) < set(after))
            self.assertIn(payload["subkey"], after)
            rotate.run(["gpg", "--batch", "--import-ownertrust"], f"{primary[0]}:6:\n", env=env)
            store = self.repo / "password-store"
            store.mkdir()
            (store / ".gpg-id").write_text(primary[0] + "\n")
            old_ciphertext = rotate.run(["gpg", "--batch", "--encrypt", "--recipient", before[-1] + "!"],
                                        b"disposable password\n", env=env, binary=True)
            entry = store / "example.gpg"
            entry.write_bytes(old_ciphertext)
            rotation = FixtureRotation(self.repo, "punky", "gpg")
            with mock.patch.dict(os.environ, {**env, "PASSWORD_STORE_DIR": str(store)}):
                rotation.reencrypt_password_store(payload)
            self.assertEqual(rotate.run(["gpg", "--batch", "--decrypt", entry], env=env, binary=True),
                             b"disposable password\n")
            listing = rotate.run(["gpg", "--batch", "--list-only", "--status-fd", "1", "--decrypt", entry], env=env)
            self.assertIn(payload["subkey"][-16:], listing)
            self.assertEqual((store / ".gpg-id").read_text(), primary[0] + "\n")

        # Exercise shared encrypted distribution and host-local keyring merges too.
        rotations = [FixtureRotation(self.repo, host, "gpg") for host in rotate.HOSTS]
        for rotation in rotations:
            rotation.encrypt(rotation.secret_file, {"pass-gpg": old, "unrelated": "preserved"}, (rotation.host,))
        for rotation in rotations:
            with mock.patch.object(rotate.getpass, "getpass", return_value=""):
                rotation.add()
            export = rotation.decrypt(rotation.secret_file)["pass-gpg"]
            with rotate.keyring([export]) as env:
                rotate.run(["gpg", "--batch", "--import-ownertrust"], f"{primary[0]}:6:\n", env=env)
                with mock.patch.dict(os.environ, env):
                    self.activate(rotation)
                _, keys = rotate.fingerprints(env)
                self.assertTrue(set(before) < set(keys))
            self.assertEqual(rotation.decrypt(rotation.secret_file)["unrelated"], "preserved")
        entry.write_bytes(old_ciphertext)
        with rotate.keyring([rotations[0].decrypt(rotations[0].secret_file)["pass-gpg"]]) as env:
            rotate.run(["gpg", "--batch", "--import-ownertrust"], f"{primary[0]}:6:\n", env=env)
            with mock.patch.dict(os.environ, {**env, "PASSWORD_STORE_DIR": str(store)}):
                rotations[0].retire()
        self.assertTrue(rotations[0].load()["finished"])
        self.assertFalse(rotations[0].pending_file.exists())

    def test_password_store_preserves_nested_recipients(self):
        store = self.repo / "password-store"
        (store / "team").mkdir(parents=True)
        (store / ".gpg-id").write_text("PRIMARY\n")
        (store / "team/.gpg-id").write_text("PRIMARY\nTEAM\n")
        (store / "entry.gpg").write_bytes(b"old ciphertext")
        (store / "team/entry.gpg").write_bytes(b"old ciphertext")
        rotation = FixtureRotation(self.repo, "punky", "gpg")
        def fake_gpg(args, data=None, **kwargs):
            self.assertEqual(args[0], "gpg")
            if "--list-keys" in args:
                return f"fpr:::::::::{args[-1]}:\n"
            return b"new ciphertext" if "--encrypt" in args else b"password"
        with mock.patch.dict(os.environ, PASSWORD_STORE_DIR=str(store)):
            with mock.patch.object(rotate, "run", side_effect=fake_gpg) as command:
                rotation.reencrypt_password_store({"primary": "PRIMARY", "subkey": "NEW"})
                encrypt_calls = [c.args[0] for c in command.call_args_list if "--encrypt" in c.args[0]]
                self.assertCountEqual(encrypt_calls, [
                    ["gpg", "--batch", "--encrypt", "--recipient", "NEW!"],
                    ["gpg", "--batch", "--encrypt", "--recipient", "NEW!", "--recipient", "TEAM"],
                ])
                self.assertEqual((store / "team/.gpg-id").read_text(), "PRIMARY\nTEAM\n")
            (store / ".gpg-id").write_text("OLD-SUBKEY!\n")
            with self.assertRaises(rotate.RotationError):
                rotation.reencrypt_password_store({})


if __name__ == "__main__":
    unittest.main()
