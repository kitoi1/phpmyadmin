# MyPHPAdmin Exploit Tool v2.0

**Enhanced Local File Inclusion Exploit for phpMyAdmin 2.6.4-pl1**  
**CVE-2005-3299**  
Author: Kasau  
Original Research: Maksymilian Arciemowicz (cXIb8O3)

---

## 📖 Description

This Perl-based tool exploits a Local File Inclusion (LFI) vulnerability in the `grab_globals.lib.php` file of phpMyAdmin version 2.6.4-pl1. The tool allows attackers to read sensitive files on the server, such as `/etc/passwd` or `/etc/shadow`, by crafting a malicious payload and sending it via HTTP(S) POST request.

It supports:
- HTTPS support using `LWP::UserAgent` and `IO::Socket::SSL`
- Custom file targeting
- Saving output to a file
- Verbose debugging
- ASCII banner and colored terminal UI

---

## ⚠️ Disclaimer

> This tool is intended for **educational** and **authorized penetration testing** purposes only.  
> Misuse of this software may violate laws and result in criminal charges.  
> The author assumes **no responsibility** for misuse or damage caused by this tool.

---

## 🛠 Requirements

Install required Perl modules using `cpan` or `cpanm`:

```bash
cpan install LWP::UserAgent IO::Socket::SSL Term::ANSIColor MIME::Base64 File::Basename Getopt::Long
