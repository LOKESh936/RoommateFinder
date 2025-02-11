import SwiftUI
import GoogleSignIn
import AuthenticationServices


struct ContentView: View {
    @StateObject var authVM = AuthViewModel()
    @State private var phoneNumber: String = ""
    @State private var otpCode: String = ""
    @State private var isOTPFieldVisible = false
    @State private var selectedCountryCode = "+1" // Default country code (USA)

    let countryCodes = ["+1 (USA)", "+91 (India)", "+44 (UK)", "+61 (Australia)", "+49 (Germany)"]

    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                Text("Welcome to Roommate Finder")
                    .font(.title)
                    .bold()
                    .padding()

                // Phone Number Authentication UI
                VStack {
                    HStack {
                        // Country Code Picker
                        Menu {
                            ForEach(countryCodes, id: \.self) { code in
                                Button(action: {
                                    selectedCountryCode = code.components(separatedBy: " ").first ?? "+1"
                                }) {
                                    Text(code)
                                }
                            }
                        } label: {
                            Text(selectedCountryCode)
                                .font(.system(size: 18))
                                .foregroundColor(.blue)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }

                        // Phone Number Input
                        TextField("Enter Phone Number", text: $phoneNumber)
                            .keyboardType(.phonePad)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .onTapGesture {
                                hideKeyboard()
                            }
                    }

                    // Send OTP Button
                    Button(action: {
                        let fullPhoneNumber = selectedCountryCode + phoneNumber
                        authVM.sendOTP(to: fullPhoneNumber)
                        isOTPFieldVisible = true
                        hideKeyboard() // Hide keyboard after pressing the button
                    }) {
                        Text("Send OTP")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    .padding(.top, 10)

                    if isOTPFieldVisible {
                        TextField("Enter OTP", text: $otpCode)
                            .keyboardType(.numberPad)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .onTapGesture {
                                hideKeyboard()
                            }

                        Button(action: {
                            authVM.verifyOTP(otpCode)
                            hideKeyboard() // Hide keyboard after pressing the button
                        }) {
                            Text("Verify OTP")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(8)
                        }
                        .padding(.top, 10)
                    }
                }
                .padding()

                // Apple Sign-In Button
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    switch result {
                    case .success:
                        authVM.signInWithApple()
                    case .failure(let error):
                        print("Apple Sign-In Error: \(error.localizedDescription)")
                    }
                }
                .frame(height: 50)
                .cornerRadius(10)
                .padding()

                // Google Sign-In Button
                Button(action: {
                    authVM.signInWithGoogle()
                }) {
                    HStack {
                        Image(systemName: "globe") // Placeholder for Google icon
                        Text("Sign in with Google")
                            .font(.system(size: 18, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(width: 250, height: 50)
                    .background(Color.red)
                    .cornerRadius(10)
                }
                .padding()

                if authVM.isLoggedIn {
                    Text("You are logged in!")
                        .foregroundColor(.green)
                        .bold()
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            hideKeyboard()
        }
        .padding()
    }
}

