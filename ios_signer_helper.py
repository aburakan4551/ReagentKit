#!/usr/bin/env python3
import base64
import os
import plistlib
import re
import sys
import subprocess

def main():
    print("="*60)
    print("🚀 ReagentKit iOS Code Signing & Provisioning Helper")
    print("="*60)
    
    # ----------------------------------------------------
    # 1. Fetch Environment Variables & Set Defaults
    # ----------------------------------------------------
    cert_b64 = (
        os.environ.get('IOS_DISTRIBUTION_CERTIFICATE_BASE64') or
        os.environ.get('BUILD_CERTIFICATE_BASE64') or
        os.environ.get('CERT_BASE64')
    )
    profile_b64 = (
        os.environ.get('IOS_PROVISIONING_PROFILE_BASE64') or
        os.environ.get('BUILD_PROVISION_PROFILE_BASE64') or
        os.environ.get('PROVISIONING_PROFILE_DATA')
    )
    p12_password = os.environ.get('IOS_DISTRIBUTION_CERTIFICATE_PASSWORD') or os.environ.get('P12_PASSWORD') or ''
    keychain_password = os.environ.get('IOS_KEYCHAIN_PASSWORD') or os.environ.get('KEYCHAIN_PASSWORD') or 'keychain_pass_123'
    
    bundle_id = os.environ.get('BUNDLE_IDENTIFIER') or 'com.yousef.ctds'
    expected_team_id = os.environ.get('APPLE_TEAM_ID') or 'B4S7M6N5U5'
    
    # ----------------------------------------------------
    # 2. Decode and Install Certificate
    # ----------------------------------------------------
    runner_temp = os.environ.get('RUNNER_TEMP') or '/tmp'
    cert_path = os.path.join(runner_temp, 'build_certificate.p12')
    keychain_path = os.path.join(runner_temp, 'app-signing.keychain-db')
    
    if not cert_b64:
        print("❌ ERROR: iOS Distribution Certificate Base64 is missing!")
        sys.exit(1)
        
    print("🔓 Decoding iOS Distribution Certificate (.p12)...")
    try:
        # Normalize base64 string
        normalized_cert_b64 = cert_b64.strip().replace('\n', '').replace(' ', '')
        cert_data = base64.b64decode(normalized_cert_b64)
        with open(cert_path, 'wb') as f:
            f.write(cert_data)
        print(f"✅ Certificate decoded successfully. size: {len(cert_data)} bytes.")
    except Exception as e:
        print(f"❌ ERROR: Failed to decode certificate: {e}")
        sys.exit(1)
        
    # ----------------------------------------------------
    # 3. Create Keychain and Import Certificate
    # ----------------------------------------------------
    print("🔑 Creating keychain and importing certificate...")
    try:
        # Clean up old keychain if exists
        subprocess.run(['security', 'delete-keychain', keychain_path], capture_output=True)
        
        # Create keychain
        subprocess.run(['security', 'create-keychain', '-p', keychain_password, keychain_path], check=True)
        subprocess.run(['security', 'set-keychain-settings', '-lut', '21600', keychain_path], check=True)
        subprocess.run(['security', 'unlock-keychain', '-p', keychain_password, keychain_path], check=True)
        
        # Import certificate
        import_cmd = [
            'security', 'import', cert_path,
            '-P', p12_password,
            '-A',
            '-t', 'cert',
            '-f', 'pkcs12',
            '-k', keychain_path
        ]
        subprocess.run(import_cmd, check=True)
        # Include login.keychain-db in search list so Xcode codesign can locate the
        # private key at archive time. Without this, signing succeeds in keychain but
        # xcodebuild cannot find the identity.
        subprocess.run([
            'security', 'list-keychains', '-d', 'user', '-s',
            keychain_path,
            os.path.expanduser('~/Library/Keychains/login.keychain-db')
        ], check=True)
        subprocess.run([
            'security', 'set-key-partition-list',
            '-S', 'apple-tool:,apple:,codesign:',
            '-s', '-k', keychain_password, keychain_path
        ], check=True)
        print("✅ Certificate successfully imported into custom keychain.")
    except Exception as e:
        print(f"❌ ERROR: Failed to configure keychain or import certificate: {e}")
        sys.exit(1)

    # ----------------------------------------------------
    # 4. Decode and Analyze Provisioning Profile
    # ----------------------------------------------------
    if not profile_b64:
        print("❌ ERROR: iOS Provisioning Profile Base64 is missing!")
        sys.exit(1)
        
    print("🔓 Decoding iOS Provisioning Profile (.mobileprovision)...")
    pp_path = os.path.join(runner_temp, 'build_pp.mobileprovision')
    try:
        normalized_profile_b64 = profile_b64.strip().replace('\n', '').replace(' ', '')
        profile_data = base64.b64decode(normalized_profile_b64)
        with open(pp_path, 'wb') as f:
            f.write(profile_data)
        print(f"✅ Provisioning profile decoded. size: {len(profile_data)} bytes.")
    except Exception as e:
        print(f"❌ ERROR: Failed to decode provisioning profile: {e}")
        sys.exit(1)
        
    # Parse mobileprovision to extract UUID, Name, TeamID, BundleID
    print("🔍 Parsing provisioning profile plist payload...")
    try:
        start_tag = b'<?xml'
        end_tag = b'</plist>'
        start_idx = profile_data.find(start_tag)
        end_idx = profile_data.find(end_tag)
        
        if start_idx == -1 or end_idx == -1:
            print("❌ ERROR: Could not find XML plist boundaries inside mobileprovision binary!")
            sys.exit(1)
            
        xml_data = profile_data[start_idx : end_idx + len(end_tag)]
        plist = plistlib.loads(xml_data)
        
        profile_uuid = plist.get('UUID')
        profile_name = plist.get('Name')
        team_ids = plist.get('TeamIdentifier', [])
        team_id = team_ids[0] if team_ids else None
        
        entitlements = plist.get('Entitlements', {})
        app_id_with_prefix = entitlements.get('application-identifier', '')
        
        print("-" * 40)
        print(f"🆔 UUID: {profile_uuid}")
        print(f"📛 Profile Name: {profile_name}")
        print(f"🏢 Team ID: {team_id}")
        print(f"📦 Entitlements App ID: {app_id_with_prefix}")
        print("-" * 40)
        
        if not profile_uuid or not profile_name or not team_id:
            print("❌ ERROR: Failed to extract vital metadata (UUID, Name, Team ID) from provisioning profile!")
            sys.exit(1)
            
    except Exception as e:
        print(f"❌ ERROR: Failed to parse plist metadata from provisioning profile: {e}")
        sys.exit(1)
        
    # ----------------------------------------------------
    # 5. Perform Rigorous Pre-Build Validations
    # ----------------------------------------------------
    print("🧐 Performing rigorous signing configuration validations...")
    
    # Check Team ID matching
    if expected_team_id and team_id != expected_team_id:
        print(f"⚠️ WARNING: Team ID in profile ({team_id}) differs from expected ({expected_team_id}). Using {team_id} from profile.")
        
    # Check Bundle Identifier matching
    # Profile app ID is usually PREFIX.BUNDLE_ID
    profile_bundle_id = app_id_with_prefix
    if '.' in app_id_with_prefix:
        profile_bundle_id = app_id_with_prefix.split('.', 1)[1]
        
    print(f"👉 Expected Bundle ID: {bundle_id}")
    print(f"👉 Profile Bundle ID: {profile_bundle_id}")
    
    # Check for wildcards like '*' or explicit matches
    if profile_bundle_id != bundle_id and profile_bundle_id != '*':
        # Check prefix matching like B4S7M6N5U5.*
        if profile_bundle_id.endswith('.*'):
            prefix = profile_bundle_id[:-2]
            if bundle_id.startswith(prefix):
                print("✅ Wildcard prefix Bundle ID matches successfully.")
            else:
                print(f"❌ ERROR: Bundle ID mismatch! App bundle id ({bundle_id}) does not match wildcard prefix profile id ({profile_bundle_id})")
                sys.exit(1)
        else:
            print(f"❌ ERROR: Bundle ID mismatch! App bundle id ({bundle_id}) does not match profile bundle id ({profile_bundle_id})")
            sys.exit(1)
    else:
        print("✅ Bundle ID validation matches successfully.")
        
    # ----------------------------------------------------
    # 6. Install Provisioning Profile
    # ----------------------------------------------------
    print("📂 Installing provisioning profile to macOS system folder...")
    home_dir = os.path.expanduser('~')
    pp_dir = os.path.join(home_dir, 'Library/MobileDevice/Provisioning Profiles')
    os.makedirs(pp_dir, exist_ok=True)
    
    installed_pp_path = os.path.join(pp_dir, f"{profile_uuid}.mobileprovision")
    with open(installed_pp_path, 'wb') as f:
        f.write(profile_data)
        
    print(f"✅ Provisioning profile installed successfully to: {installed_pp_path}")
    
    # ----------------------------------------------------
    # 7. Harden project.pbxproj to Manual signing
    # ----------------------------------------------------
    print("🛠️ Hardening Xcode project.pbxproj configurations...")
    pbxproj_path = 'ios/Runner.xcodeproj/project.pbxproj'
    
    if not os.path.exists(pbxproj_path):
        print(f"❌ ERROR: Xcode project file does not exist at: {pbxproj_path}")
        sys.exit(1)
        
    try:
        with open(pbxproj_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # Find the XCBuildConfiguration section
        start_tag_str = '/* Begin XCBuildConfiguration section */'
        end_tag_str = '/* End XCBuildConfiguration section */'
        start_idx = content.find(start_tag_str)
        end_idx = content.find(end_tag_str)
        
        if start_idx == -1 or end_idx == -1:
            print("❌ ERROR: Could not find XCBuildConfiguration section in project.pbxproj!")
            sys.exit(1)
            
        config_section = content[start_idx:end_idx]
        blocks = config_section.split('};\n')
        new_blocks = []
        
        for block in blocks:
            # Check if this block belongs to Runner target configurations
            if f'PRODUCT_BUNDLE_IDENTIFIER = {bundle_id}' in block:
                # Force Manual Code Sign
                block = re.sub(r'CODE_SIGN_STYLE\s*=\s*[^;]+;', 'CODE_SIGN_STYLE = Manual;', block)
                block = re.sub(r'DEVELOPMENT_TEAM\s*=\s*[^;]+;', f'DEVELOPMENT_TEAM = {team_id};', block)
                block = re.sub(r'"DEVELOPMENT_TEAM\[sdk=iphoneos\*\]"\s*=\s*[^;]+;', f'"DEVELOPMENT_TEAM[sdk=iphoneos*]" = {team_id};', block)
                
                # Replace or Inject PROVISIONING_PROFILE and PROVISIONING_PROFILE_SPECIFIER
                if 'PROVISIONING_PROFILE_SPECIFIER' in block:
                    block = re.sub(r'PROVISIONING_PROFILE_SPECIFIER\s*=\s*[^;]+;', f'PROVISIONING_PROFILE_SPECIFIER = "{profile_name}";\n\t\t\t\tPROVISIONING_PROFILE = "{profile_uuid}";', block)
                else:
                    # Inject them at the beginning of buildSettings
                    block = block.replace('buildSettings = {', f'buildSettings = {{\n\t\t\t\tPROVISIONING_PROFILE = "{profile_uuid}";\n\t\t\t\tPROVISIONING_PROFILE_SPECIFIER = "{profile_name}";')
                
                block = re.sub(r'"PROVISIONING_PROFILE_SPECIFIER\[sdk=iphoneos\*\]"\s*=\s*[^;]+;', f'"PROVISIONING_PROFILE_SPECIFIER[sdk=iphoneos*]" = "{profile_name}";', block)
                
                # Force Apple Distribution certificate
                block = re.sub(r'CODE_SIGN_IDENTITY\s*=\s*[^;]+;', 'CODE_SIGN_IDENTITY = "Apple Distribution";', block)
                block = re.sub(r'"CODE_SIGN_IDENTITY\[sdk=iphoneos\*\]"\s*=\s*[^;]+;', '"CODE_SIGN_IDENTITY[sdk=iphoneos*]" = "Apple Distribution";', block)
                
            new_blocks.append(block)
            
        new_config_section = '};\n'.join(new_blocks)
        new_content = content[:start_idx] + new_config_section + content[end_idx:]
        
        with open(pbxproj_path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print("✅ project.pbxproj successfully hardened with strict Manual signing parameters.")
    except Exception as e:
        print(f"❌ ERROR: Failed to harden project.pbxproj: {e}")
        sys.exit(1)
        
    # ----------------------------------------------------
    # 8. Write GitHub Actions Outputs / Environment
    # ----------------------------------------------------
    github_env = os.environ.get('GITHUB_ENV')
    if github_env:
        try:
            with open(github_env, 'a', encoding='utf-8') as f:
                f.write(f"UUID={profile_uuid}\n")
                f.write(f"PROFILE_NAME={profile_name}\n")
                f.write(f"APPLE_TEAM_ID={team_id}\n")
            print("✅ GitHub environment variables successfully populated.")
        except Exception as e:
            print(f"⚠️ Failed to write to GITHUB_ENV: {e}")
            
    # ----------------------------------------------------
    # 9. Decode and Write GoogleService-Info.plist if available
    # ----------------------------------------------------
    google_service_plist = os.environ.get('GOOGLE_SERVICE_INFO_PLIST')
    if google_service_plist:
        plist_path = 'ios/Runner/GoogleService-Info.plist'
        print(f"📄 Writing GoogleService-Info.plist to {plist_path}...")
        try:
            plist_content = google_service_plist.strip()
            # Try to decode if base64 encoded
            if not plist_content.startswith('<?xml') and not plist_content.startswith('<plist'):
                try:
                    decoded_bytes = base64.b64decode(plist_content)
                    plist_content = decoded_bytes.decode('utf-8')
                except Exception:
                    pass
            
            # Ensure the directory exists
            os.makedirs(os.path.dirname(plist_path), exist_ok=True)
            with open(plist_path, 'w', encoding='utf-8') as f:
                f.write(plist_content)
            print("✅ GoogleService-Info.plist successfully written.")
        except Exception as e:
            print(f"❌ ERROR: Failed to write GoogleService-Info.plist: {e}")
            sys.exit(1)
    else:
        print("⚠️ WARNING: GOOGLE_SERVICE_INFO_PLIST environment variable is missing. Build may fail if file is missing.")
            
    print("="*60)
    print("🎉 ALL iOS SIGNING PREPARATIONS ARE 100% SUCCESSFUL AND VALIDATED!")
    print("="*60)

if __name__ == '__main__':
    main()
