# GPG Key Distribution Methods

1. **Key Servers**

   - **Upload to a Public Key Server**:
     You can upload your public key to a key server, which allows others to search for and download your key using your email address or key fingerprint.

     ```bash
     gpg --send-keys <key-fingerprint>
     ```

     - Common key servers:
       - `hkps://keys.openpgp.org`
       - `hkps://pgp.mit.edu`
       - `hkps://keyserver.ubuntu.com`

   - **Retrieving from a Key Server**:
     Others can retrieve your key using:
     ```bash
     gpg --recv-keys <key-fingerprint>
     ```

2. **Publishing on Your Website**

   - **Host the Public Key on Your Website**:
     Upload the `publickey.asc` file to your website or a dedicated page.

     - Example: `https://yourdomain.com/publickey.asc`

   - **Include Fingerprint and Download Instructions**:
     You can also provide instructions on how to import the key directly from your website:
     ```bash
     curl -O https://yourdomain.com/publickey.asc
     gpg --import publickey.asc
     ```

3. **Include in Email Signature or Contact Information**

   - **Email Signature**:
     Add your GPG fingerprint and a link to download your public key in your email signature. This allows people to easily find and import your key.

   - **Contact Page**:
     Add the public key or a link to it on your personal or company contact page.

4. **GitHub GPG Key Integration**

   - **Add Your Public Key to GitHub**:
     You can add your GPG key to your GitHub account. This allows anyone who interacts with your GitHub profile to verify signed commits.
     - Navigate to GitHub > Settings > SSH and GPG keys > New GPG key.
     - Paste your public key there.
   - This will also show your verified commits with a badge.

5. **QR Code**

   - **Generate a QR Code for Your Public Key**:
     You can generate a QR code that links to your public key or contains the key data itself. This is useful for presentations, business cards, or anywhere you want to distribute your key quickly.
     - You can use a service like `qrencode` to generate the QR code.

6. **Direct Sharing via Messaging Apps or Social Media**
   - **Share via Encrypted Messaging**:
     You can share your public key directly with trusted contacts via encrypted messaging apps (e.g., Signal, WhatsApp) or as a pinned tweet/post on social media profiles.

Summary:
Using these methods, you can ensure that your public GPG key is easily accessible to anyone who needs it, while your private key remains secure.

---

[Back to README](../README.md)

```

```
