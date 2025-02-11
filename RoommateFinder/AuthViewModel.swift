import SwiftUI
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import GoogleSignInSwift
import AuthenticationServices
import CryptoKit

class AuthViewModel: NSObject, ObservableObject {
    @Published var isLoggedIn = false
    @Published var verificationID: String?
    private var currentNonce: String?
    
    
    // MARK: - Phone Number Authentication
    func sendOTP(to phoneNumber: String) {
        print("📲 Sending OTP to: \(phoneNumber)")

        Auth.auth().settings?.isAppVerificationDisabledForTesting = false  // Disable in production

        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { verificationID, error in
            if let error = error {
                print("❌ OTP Error: \(error.localizedDescription)")
                return
            }
            DispatchQueue.main.async {
                self.verificationID = verificationID
            }
            print("✅ OTP sent successfully to \(phoneNumber)")
        }
    }


    func verifyOTP(_ otpCode: String) {
        guard let verificationID = verificationID else {
            print("Error: No verification ID found.")
            return
        }

        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: otpCode
        )

        Auth.auth().signIn(with: credential) { authResult, error in
            if let error = error {
                print("Error verifying OTP: \(error.localizedDescription)")
                return
            }
            print("User signed in with Phone Number")
            DispatchQueue.main.async {
                self.isLoggedIn = true
            }
        }
    }

    

    // MARK: - Google Sign-In
    func signInWithGoogle() {
           guard let clientID = FirebaseApp.app()?.options.clientID else {
               print("Error: No Firebase Client ID found.")
               return
           }

           guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                 let rootViewController = windowScene.windows.first?.rootViewController else {
               print("Error: No root view controller found.")
               return
           }

           GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { signInResult, error in
               if let error = error {
                   print("Google Sign-In Error: \(error.localizedDescription)")
                   return
               }

               guard let user = signInResult?.user,
                     let idToken = user.idToken?.tokenString else {
                   print("Error: Missing Google user data")
                   return
               }

               let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)

               Auth.auth().signIn(with: credential) { authResult, error in
                   if let error = error {
                       print("Firebase Sign-In Error: \(error.localizedDescription)")
                       return
                   }
                   print("User signed in with Google")
                   DispatchQueue.main.async {
                       self.isLoggedIn = true
                   }
               }
           }
       }

    // MARK: - Apple Sign-In
    func signInWithApple() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        let nonce = randomNonceString()
        currentNonce = nonce
        request.nonce = sha256(nonce)

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.performRequests()
    }

    private func randomNonceString(length: Int = 32) -> String {
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                _ = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                return random
            }

            randoms.forEach { random in
                if remainingLength == 0 { return }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Apple Sign-In Delegate
extension AuthViewModel: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                print("Error: Nonce is missing.")
                return
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Error: Unable to fetch identity token.")
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Error: Unable to serialize token.")
                return
            }

            let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: idTokenString, rawNonce: nonce)
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    print("Firebase Sign-In Error: \(error.localizedDescription)")
                    return
                }

                print("Successfully signed in with Apple!")
                DispatchQueue.main.async {
                    self.isLoggedIn = true
                }
            }
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Apple Sign-In Error: \(error.localizedDescription)")
    }
}
