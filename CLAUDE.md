# Text Assistant - Apple Sign In Debug Context

## Current Status
- App successfully authenticates locally but Supabase integration is failing
- Error: "unacceptable audience in id_token: [cole.test-assistant]"
- Using bypass authentication to allow app to work while debugging Supabase

## Configuration Details

### Apple Developer Console
- **Team ID**: TT3Y78TSSQ
- **Key ID**: G834N45JGZ  
- **App Bundle ID**: cole.text-assistant (shows in Xcode)
- **Service ID**: cole.test-assistant.service (created to match error)
- **Private Key**: AuthKey_G834N45JGZ.p8

### Supabase Configuration
- **Project ID**: hhfrjzypqunwalpfujeb
- **Project URL**: https://hhfrjzypqunwalpfujeb.supabase.co
- **Client ID**: cole.test-assistant.service
- **Secret Key**: JWT token generated from script

### Service ID Configuration
- **Domains**: hhfrjzypqunwalpfujeb.supabase.co
- **Return URLs**: https://hhfrjzypqunwalpfujeb.supabase.co/auth/v1/callback

## Issue Summary
1. App Bundle ID shows as `cole.text-assistant` in Xcode
2. Error message shows `cole.test-assistant` (test vs text discrepancy)
3. Created Service ID to match error message but still failing
4. Console logs not appearing in Xcode
5. Using UI-based debug info in MainTabView to show auth status

## JWT Generation Script
Located at: `/Users/colebriggs/apple-jwt.js/generate-apple-jwt-final.js`
- Generates JWT token for Supabase Apple provider
- Uses ES256 algorithm with Apple private key

## Next Steps When Resuming
1. Verify actual Bundle ID in built app (might differ from Xcode)
2. Check if Apple Developer portal shows correct App ID
3. Consider if there's a build configuration causing the test/text mismatch
4. May need to check Supabase logs for more detailed error info
5. Verify Service ID is properly configured with correct URLs

## Bypass Authentication
Currently using bypass in AuthenticationManager.swift:
- If Supabase fails, sets `userEmail = "test@example.com"`
- This allows testing the app while debugging auth issues
- Debug info at top of MainTabView shows if using bypass or real auth

## Files Modified
- AuthenticationManager.swift - Added bypass logic and error tracking
- SimpleSupabaseService.swift - Simplified Supabase client
- MainTabView.swift - Added debug info display
- LoginView.swift - Added debug tap counter
- JWT scripts in /Users/colebriggs/apple-jwt.js/