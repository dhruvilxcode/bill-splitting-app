import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitty/app/login/controller/auth_controller.dart';
import 'package:splitty/app/login/login_screen.dart';
import 'package:splitty/common/alert_dialog.dart';
import 'package:splitty/config/images.dart';
import 'package:splitty/providers/user_provider.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  final bool isFirstTimeSetup;

  const ProfileSetupScreen({Key? key, this.isFirstTimeSetup = false})
      : super(key: key);

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  String image = memojis.first.imageURL;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController upiIdController = TextEditingController();

  bool _btnSaveTapped = false;

  @override
  void initState() {
    final user = ref.read(userProvider);

    nameController.text = user.name;
    upiIdController.text = user.upiId;

    if (user.profileImage != "") {
      setState(() {
        image = user.profileImage;
      });
    }

    super.initState();
  }

  _showMemojiSelectionSheet() {
    showModalBottomSheet(
      context: context,
      enableDrag: true,
      isDismissible: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (dragScrollSheetContext, scrollController) {
            return Padding(
              padding: const EdgeInsets.only(top: 20, left: 30, right: 30),
              child: GridView.count(
                crossAxisCount: 3,
                controller: scrollController,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                children: memojis
                    .map(
                      (m) => GestureDetector(
                        onTap: () {
                          setState(() {
                            setState(() {
                              image = m.imageURL;
                            });
                            Navigator.pop(ctx);
                          });
                        },
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[350],
                          backgroundImage:
                              CachedNetworkImageProvider(m.imageURL),
                        ),
                      ),
                    )
                    .toList(),
              ),
            );
          },
        );
      },
    );
  }

  void _saveUserInfo() async {
    setState(() {
      _btnSaveTapped = true;
    });

    try {
      String name = nameController.text;
      String upiId = upiIdController.text;

      if (name.isNotEmpty) {
        NavigatorState navigatorState = Navigator.of(context);
        await addUserInfo(name: name, profileImage: image, upiId: upiId);

        final oldUser = ref.read(userProvider);
        ref.read(userProvider.state).state = UserModel(
          name: name,
          phoneNumber: oldUser.phoneNumber,
          profileImage: image,
          upiId: upiId,
          isMineProfile: true,
          uid: oldUser.uid,
        );

        if (widget.isFirstTimeSetup) {
          navigatorState.pushNamedAndRemoveUntil("/main", (route) => false);
        } else {
          showAlertDialog(
            context: context,
            title: "Done ✅",
            description: "Your details are saved.",
          );
        }
      } else {
        showAlertDialog(
            context: context,
            title: "oops!",
            description: "Provide your name.");
      }
    } catch (e) {
      log("$e");
      showAlertDialog(context: context, title: "oops!", description: "$e");
    }

    setState(() {
      _btnSaveTapped = false;
    });
  }

  _btnLogoutTap() async {
    try {
      NavigatorState navigatorState = Navigator.of(context);
      await logOut();

      navigatorState.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      log("$e");
      showAlertDialog(
          context: context,
          title: "oops!",
          description: "something went wrong.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Profile Setup"),
        ),
        body: ListView(
          children: [
            const SizedBox(height: 60),
            GestureDetector(
              onTap: () {
                _showMemojiSelectionSheet();
              },
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: CachedNetworkImageProvider(image),
                  ),
                  const SizedBox(height: 10),
                  const Text("click to change profile image"),
                ],
              ),
            ),
            const SizedBox(height: 60),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 30),
              child: const Text("Your Name"),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              margin: const EdgeInsets.symmetric(horizontal: 30),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: nameController,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
                enableSuggestions: true,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "Enter Your Name here...",
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 30),
              child: const Text("Your UPI ID"),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              margin: const EdgeInsets.symmetric(horizontal: 30),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: upiIdController,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.done,
                enableSuggestions: true,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "Enter your UPI ID...",
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: MediaQuery.of(context).size.width,
              margin: const EdgeInsets.symmetric(horizontal: 30),
              child: ElevatedButton(
                onPressed: _btnSaveTapped ? null : _saveUserInfo,
                child: const Text("save"),
              ),
            ),
            if (!widget.isFirstTimeSetup) ...[
              const SizedBox(height: 80),
              Container(
                width: MediaQuery.of(context).size.width,
                margin: const EdgeInsets.symmetric(horizontal: 30),
                child: TextButton(
                  onPressed: () {
                    _btnLogoutTap();
                  },
                  style: ButtonStyle(
                    foregroundColor: MaterialStateProperty.all(Colors.red),
                    padding: MaterialStateProperty.all(
                      const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 20,
                      ),
                    ),
                    overlayColor:
                        MaterialStateProperty.all(Colors.red.withOpacity(.4)),
                    shape: MaterialStateProperty.all(RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                  ),
                  child: const Text("Logout"),
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
