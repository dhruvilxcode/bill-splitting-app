import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';
import 'package:splitty/app/main_screen/main_screen.dart';
import 'package:splitty/app/login/profile_setup_screen.dart';
import 'package:splitty/common/alert_dialog.dart';
import 'package:splitty/config/colors.dart';
import 'package:splitty/config/images.dart';
import 'package:splitty/providers/user_provider.dart';

import 'controller/auth_controller.dart';

class OtpSendAndVerifyScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  const OtpSendAndVerifyScreen({Key? key, required this.phoneNumber})
      : super(key: key);

  @override
  ConsumerState<OtpSendAndVerifyScreen> createState() =>
      _OtpSendAndVerifyScreenState();
}

class _OtpSendAndVerifyScreenState
    extends ConsumerState<OtpSendAndVerifyScreen> {
  final TextEditingController _pinPutController = TextEditingController();
  final FocusNode _pinPutFocusNode = FocusNode();

  final FirebaseAuth auth = FirebaseAuth.instance;
  String _verificationId = '';
  bool _isVerifyingOTP = false;

  @override
  void initState() {
    // send OTP to phone number

    sendOTP(phoneNumber: widget.phoneNumber);

    super.initState();
  }

  void sendOTP({required String phoneNumber}) async {
    try {
      await auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: _signInWithPhoneOTP,
        verificationFailed: (FirebaseAuthException e) {
          debugPrint(e.toString());
          debugPrint(e.code);

          if (e.code == 'invalid-phone-number') {
            showAlertDialog(
              context: context,
              title: "oops!",
              description: "Invalid phone number provided.",
            );
          } else {
            showAlertDialog(
              context: context,
              title: "oops!",
              description: "Something went wrong! Try again later.",
            );
          }
        },
        codeSent: (String vId, int? resendToken) async {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("OTP sent successfully."),
            ),
          );
          setState(() {
            _verificationId = vId;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-phone-number') {
        showAlertDialog(
          context: context,
          title: "oops!",
          description: "Invalid phone number provided.",
        );
      } else {
        showAlertDialog(
          context: context,
          title: "oops!",
          description: "Something went wrong! Try again later.",
        );
      }
    }
  }

  void verifyOTP(String otp) async {
    setState(() {
      _isVerifyingOTP = true;
    });
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: _verificationId, smsCode: otp);
      _signInWithPhoneOTP(credential);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isVerifyingOTP = false;
      });

      debugPrint(e.toString());
      debugPrint(e.code);
      if (e.code == "invalid-verification-code") {
        showAlertDialog(
          context: context,
          title: "oops!",
          description: "OTP verification failed, provide correct OTP.",
        );
      } else {
        showAlertDialog(
          context: context,
          title: "oops!",
          description: "Something went wrong, try again later.",
        );
      }
    }
  }

  _signInWithPhoneOTP(PhoneAuthCredential credential) async {
    User? user = (await auth.signInWithCredential(credential)).user;

    if (user != null) {
      Map<String, dynamic>? userData = await getUserInfo();
      if (userData != null) {
        UserModel userModel = UserModel(
          name: userData["name"] ?? "",
          phoneNumber: user.phoneNumber ?? "",
          profileImage: userData["profileImage"] ?? "",
          upiId: userData["upiId"] ?? "",
          uid: user.uid,
          isMineProfile: true,
        );
        ref.read(userProvider.state).state = userModel;

        if (userModel.name != "" && userModel.phoneNumber != "") {
          // goto main screen
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const MainScreen(),
            ),
            (route) => false,
          );
        } else {
          // goto profile setup
          UserModel userModel = UserModel(
            name: userData["name"] ?? "",
            phoneNumber: user.phoneNumber ?? "",
            profileImage: userData["profileImage"] ?? "",
            upiId: userData["upiId"] ?? "",
            uid: user.uid,
            isMineProfile: true,
          );
          ref.read(userProvider.state).state = userModel;

          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const ProfileSetupScreen(isFirstTimeSetup: true),
            ),
            (route) => false,
          );
        }
      } else {
        // goto profile setup
        UserModel userModel = UserModel(
          name: "",
          phoneNumber: user.phoneNumber ?? "",
          profileImage: memojis.first.imageURL,
          upiId: "",
          uid: user.uid,
          isMineProfile: true,
        );
        ref.read(userProvider.state).state = userModel;

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const ProfileSetupScreen(isFirstTimeSetup: true),
          ),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 80),
            const Center(
              child: Image(
                image: AssetImage("assets/splitty_text_logo.png"),
                height: 50,
              ),
            ),
            const SizedBox(height: 60),
            Center(
              child: Text(
                "Enter OTP, sent on your ${widget.phoneNumber}",
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 60),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 30),
              child: Pinput(
                enabled: !_isVerifyingOTP,
                length: 6,
                focusNode: _pinPutFocusNode,
                controller: _pinPutController,
                defaultPinTheme: PinTheme(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFFECECEC),
                    border: Border.all(color: const Color(0xFFB3B3B3)),
                  ),
                ),
                focusedPinTheme: PinTheme(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFFECECEC),
                    border: Border.all(color: primaryColor),
                  ),
                ),
                onCompleted: (String pin) async {
                  _pinPutFocusNode.unfocus();

                  verifyOTP(pin);
                },
              ),
            ),
            const SizedBox(height: 30),
            Container(
              width: size.width,
              margin: const EdgeInsets.symmetric(horizontal: 30),
              child: ElevatedButton(
                onPressed: _isVerifyingOTP
                    ? null
                    : () {
                        String otp = _pinPutController.text;
                        verifyOTP(otp);
                      },
                child: const Text("verify OTP"),
              ),
            ),
            const SizedBox(height: 60),
            Container(
              width: size.width,
              margin: const EdgeInsets.symmetric(horizontal: 30),
              child: TextButton(
                onPressed: () {
                  showAlertDialog(
                    context: context,
                    title: "sorry!",
                    description:
                        "This app uses Google's Services, i'm using Free Plan, so there is Daily Limit of 50 SMS,\n\n if you want to try funcationality of App, use following Test Number and OTP.\n\nPhone: +91 98765 43210\nOTP:123456",
                  );
                },
                child: const Text("didn't got OTP?"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
