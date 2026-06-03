# بناء iOS عبر GitHub Actions

هذا المشروع يحتوي على workflow في:

`.github/workflows/ios-app-store.yml`

وظيفته بناء ملف Flutter iOS موقّع بصيغة `.ipa` على GitHub Actions.

## أسرار GitHub المطلوبة

أضف القيم التالية من GitHub:

`Repository Settings` -> `Secrets and variables` -> `Actions` -> `New repository secret`

| Secret name | Value |
| --- | --- |
| `IOS_DISTRIBUTION_CERTIFICATE_BASE64` | محتوى شهادة Apple Distribution بصيغة `.p12` بعد تحويله إلى Base64. |
| `IOS_DISTRIBUTION_CERTIFICATE_PASSWORD` | كلمة مرور شهادة `.p12`. |
| `IOS_KEYCHAIN_PASSWORD` | أي كلمة مرور قوية ومؤقتة للـ keychain داخل GitHub Actions. |
| `IOS_PROVISIONING_PROFILE_BASE64` | محتوى App Store provisioning profile بصيغة `.mobileprovision` بعد تحويله إلى Base64. استخدم هذا السر فقط لتجنب الالتباس. |

| `IOS_GOOGLE_SERVICE_INFO_PLIST_BASE64` | اختياري لكنه مفضل: محتوى `ios/Runner/GoogleService-Info.plist` بعد تحويله إلى Base64. |
| `APP_STORE_CONNECT_API_KEY_ID` | مطلوب فقط إذا فعّلت رفع TestFlight من داخل workflow. |
| `APP_STORE_CONNECT_API_ISSUER_ID` | مطلوب فقط إذا فعّلت رفع TestFlight من داخل workflow. |
| `APP_STORE_CONNECT_API_KEY_BASE64` | مطلوب فقط إذا فعّلت رفع TestFlight: محتوى ملف `.p8` بعد تحويله إلى Base64. |

> ملاحظة: إذا كانت القيم الثلاث متوفرة، فسيقوم workflow بعد بناء `.ipa` برفعه تلقائيًا إلى App Store Connect باستخدام `xcrun altool`.
>
> تأكد من أن `IOS_PROVISIONING_PROFILE_BASE64` يحتوي على ملف `.mobileprovision` واحد فقط. لا تضع أكثر من provisioning profile في سر واحد، ولا تستخدم أسرار بديلة في نفس الوقت.
>
> يجب أن يكون الملف النهائي هو `ReagentKit_App_Store_Profile.mobileprovision`.

## تحويل الملفات إلى Base64

على macOS:

```bash
base64 -i ReagentKit.p12 | pbcopy
base64 -i ReagentKit_App_Store_Profile.mobileprovision | pbcopy
base64 -i ios/Runner/GoogleService-Info.plist | pbcopy
base64 -i AuthKey_XXXXXXXXXX.p8 | pbcopy
```

بعد كل أمر، الصق القيمة المنسوخة في GitHub Secret المناسب.

## تشغيل البناء

1. افتح المستودع في GitHub.
2. اذهب إلى `Actions`.
3. اختر `Build iOS IPA`.
4. اضغط `Run workflow`.
5. أدخل `build_name` و `build_number` جديدين. يجب أن يكون `build_number` أعلى من آخر رقم قبله App Store Connect؛ الرقم الحالي المقترح هو `123`.
6. في أول تجربة، اترك `upload_to_testflight` غير مفعّل.
7. بعد انتهاء البناء، حمّل ملف `.ipa` من artifacts.

الـ workflow يستخدم runner باسم `macos-26` حتى يتم البناء باستخدام Xcode/iOS SDK حديث يطابق شرط Apple.
