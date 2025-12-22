# Windows Keystore Setup Guide

## Creating the Keystore on Windows

On Windows PowerShell, use one of these methods:

### Method 1: Using PowerShell Environment Variable (Recommended)

```powershell
keytool -genkey -v -keystore "$env:USERPROFILE\worbix-release-key.jks" -keyalg RSA -keysize 2048 -validity 10000 -alias worbix
```

This will create the keystore in your user home directory (e.g., `C:\Users\LENOVO\worbix-release-key.jks`)

### Method 2: Using Absolute Path

```powershell
keytool -genkey -v -keystore "C:\Users\LENOVO\worbix-release-key.jks" -keyalg RSA -keysize 2048 -validity 10000 -alias worbix
```

Replace `LENOVO` with your actual username.

### Method 3: Create in Project Directory (Not Recommended for Production)

```powershell
keytool -genkey -v -keystore "android\worbix-release-key.jks" -keyalg RSA -keysize 2048 -validity 10000 -alias worbix
```

**Note:** If you use this method, make sure the keystore file is in `.gitignore` (it already is).

## Important Password Requirements

- **Keystore password**: Must be at least 6 characters
- **Key password**: Must be at least 6 characters (you can use the same as keystore password)
- **Remember these passwords** - you'll need them for the `key.properties` file

## After Creating the Keystore

1. **Note the location** of your keystore file (e.g., `C:\Users\LENOVO\worbix-release-key.jks`)

2. **Create `android/key.properties`** file:
   ```powershell
   Copy-Item android\key.properties.template android\key.properties
   ```

3. **Edit `android/key.properties`** with your actual values:
   ```properties
   storePassword=your_keystore_password_here
   keyPassword=your_key_password_here
   keyAlias=worbix
   storeFile=C:\\Users\\LENOVO\\worbix-release-key.jks
   ```
   
   **Important:** Use double backslashes (`\\`) or forward slashes (`/`) in the path:
   - `C:\\Users\\LENOVO\\worbix-release-key.jks` (double backslashes)
   - OR `C:/Users/LENOVO/worbix-release-key.jks` (forward slashes)

## Example Complete Setup

1. Run the keytool command (you'll be prompted for information):
   ```powershell
   keytool -genkey -v -keystore "$env:USERPROFILE\worbix-release-key.jks" -keyalg RSA -keysize 2048 -validity 10000 -alias worbix
   ```

2. Enter the required information when prompted:
   - Keystore password: (at least 6 characters)
   - Re-enter password: (same password)
   - First and last name: `Alvin Regi`
   - Organizational unit: `Zenith Syntax`
   - Organization: `Zenith Syntax`
   - City: `Kottayam`
   - State: `Kerala`
   - Country code: `IN`
   - Confirm: `yes`

3. Create key.properties:
   ```powershell
   Copy-Item android\key.properties.template android\key.properties
   ```

4. Edit `android/key.properties` with your passwords and path.

## Verify Your Setup

After setup, you can verify by building a release:

```powershell
flutter build appbundle --release
```

If the keystore is configured correctly, the build will succeed. If not, you'll see signing errors.







