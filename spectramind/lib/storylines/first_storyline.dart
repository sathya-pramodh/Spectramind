import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:spectramind/components/base_storyline.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:spectramind/components/from_index.dart';
import 'package:spectramind/db.dart';
import 'package:flutter_tts/flutter_tts.dart';

class FirstStoryLine extends HookWidget {
  final User? user;
  const FirstStoryLine({super.key, required this.user});

  Color? getOptionColor(int index, int selectedOption, int correctOption) {
    if (selectedOption == index) {
      if (correctOption == index) return Colors.greenAccent;
      if (correctOption == -1) return Colors.orangeAccent;
      return Colors.redAccent;
    } else {
      if (correctOption == index) return Colors.greenAccent;
      return Colors.lightBlue[50];
    }
  }

  @override
  Widget build(BuildContext context) {
    return baseWidget(context, "First Story Line", _body(context), user);
  }

  Widget _body(BuildContext context) {
    late FlutterTts tts = FlutterTts();
    final displayOptions = useState(false);
    final startStory = useState(false);
    final displayText = useState("Start");
    final selectedOption = useState(-1);
    final questionIndex = useState(1);
    final correctOption = useState(-1);
    final submitted = useState(false);
    final displayReply = useState(false);
    final displayQuestion = useState(false);
    tts.setSpeechRate(0.6);

    final parsableText = questionFromIndex(1, questionIndex.value);
    final text = parsableText
        .map((paragraph) => TypewriterAnimatedText(
              paragraph,
              cursor: '',
              speed: const Duration(milliseconds: 75),
              textAlign: TextAlign.center,
              textStyle: const TextStyle(
                  fontSize: 20,
                  fontFamily: 'Hind',
                  fontWeight: FontWeight.w400),
            ))
        .toList();
    List<ListTile> options = [];
    List<String> parsableOptions = optionsFromIndex(1, questionIndex.value);
    for (var i = 1; i <= parsableOptions.length; i++) {
      options.add(ListTile(
          tileColor:
              getOptionColor(i, selectedOption.value, correctOption.value),
          onTap: () => selectedOption.value = i,
          title: Column(children: [
            Text(
              parsableOptions[i - 1],
              style: const TextStyle(
                  fontSize: 20,
                  fontFamily: 'Hind',
                  fontWeight: FontWeight.w400),
            ),
            const Divider(),
          ])));
    }
    return Column(children: [
      const Text("Henry: The Autistic Parrot",
          style: TextStyle(
            fontFamily: 'LuckiestGuy',
            fontSize: 20,
          )),
      const SizedBox(height: 10),
      const CircleAvatar(
          backgroundImage: AssetImage("lib/images/Pheonix.png"), radius: 50),
      const SizedBox(height: 5),
      (displayQuestion.value)
          ? Container(
              width: MediaQuery.of(context).size.width - 20,
              decoration: BoxDecoration(
                  color: Colors.lightBlue[50],
                  borderRadius: const BorderRadius.all(Radius.circular(10))),
              child: AnimatedTextKit(
                animatedTexts: text,
                repeatForever: false,
                pause: const Duration(seconds: 5),
                totalRepeatCount: 1,
                onFinished: () {
                  displayOptions.value = true;
                  displayText.value = "Restart";
                },
                onNextBeforePause: (idx, b) async {
                  await tts.speak(parsableText[idx]);
                },
                onNext: (idx, b) async {
                  await tts.awaitSpeakCompletion(true);
                },
              ),
            )
          : const SizedBox(height: 10),
      (displayOptions.value)
          ? Column(children: [
              (displayReply.value)
                  ? Container(
                      width: MediaQuery.of(context).size.width - 20,
                      decoration: BoxDecoration(
                          color: Colors.lightBlue[50],
                          borderRadius:
                              const BorderRadius.all(Radius.circular(10))),
                      child: AnimatedTextKit(
                          animatedTexts: [
                            TypewriterAnimatedText(
                                cursor: '',
                                speed: const Duration(milliseconds: 75),
                                textAlign: TextAlign.center,
                                textStyle: const TextStyle(
                                    fontSize: 20,
                                    fontFamily: 'Hind',
                                    fontWeight: FontWeight.w400),
                                replyFromIndex(1, selectedOption.value,
                                    correctOption.value, questionIndex.value))
                          ],
                          repeatForever: false,
                          totalRepeatCount: 1,
                          pause: const Duration(seconds: 5),
                          onFinished: () {
                            submitted.value = true;
                          },
                          onNextBeforePause: (idx, b) async {
                            await tts.speak(replyFromIndex(
                                1,
                                selectedOption.value,
                                correctOption.value,
                                questionIndex.value));
                          },
                          onNext: (idx, b) async {
                            await tts.awaitSpeakCompletion(true);
                          }),
                    )
                  : const SizedBox(height: 10),
              Column(children: [
                ListBody(children: options),
              ]),
              const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                (!submitted.value)
                    ? ElevatedButton(
                        onPressed: () {
                          startStory.value = false;
                          displayText.value = "Start";
                          displayOptions.value = false;
                          selectedOption.value = -1;
                          correctOption.value = -1;
                          displayReply.value = false;
                          displayQuestion.value = false;
                          submitted.value = false;
                        },
                        child: Text(displayText.value,
                            style: const TextStyle(
                                backgroundColor: Colors.transparent)))
                    : const SizedBox(height: 0, width: 0),
                (!submitted.value)
                    ? ElevatedButton(
                        onPressed: () {
                          if (selectedOption.value != -1) {
                            FirebaseFirestore.instance
                                .collection('questions')
                                .where('qid',
                                    isEqualTo:
                                        int.parse("1${questionIndex.value}"))
                                .get()
                                .then((value) {
                              correctOption.value = value.docs[0].get("answer");
                              int inc = 1;
                              if (correctOption.value == selectedOption.value) {
                                inc = 5;
                              }
                              FirebaseFirestore.instance
                                  .collection('users')
                                  .where('name', isEqualTo: user?.email)
                                  .get()
                                  .then((value) async {
                                int multiplier =
                                    value.docs[0].get('multiplier');
                                await DatabaseManager().updateUserTokens(
                                    email: user?.email,
                                    tokens: value.docs[0].get('tokens') +
                                        inc * multiplier);
                              });
                              displayReply.value = true;
                              displayQuestion.value = false;
                              submitted.value = true;
                            });
                          }
                        },
                        child: const Text("Submit",
                            style:
                                TextStyle(backgroundColor: Colors.transparent)))
                    : ElevatedButton(
                        onPressed: () {
                          questionIndex.value++;
                          if (questionIndex.value <= 4) {
                            displayOptions.value = false;
                            selectedOption.value = -1;
                            correctOption.value = -1;
                            displayReply.value = false;
                            displayQuestion.value = true;
                            submitted.value = false;
                          } else if (questionIndex.value == 5) {
                            displayReply.value = false;
                            displayQuestion.value = true;
                          } else {
                            FirebaseFirestore.instance
                                .collection('users')
                                .where('name', isEqualTo: user?.email)
                                .get()
                                .then((matches) {
                              int completed = matches.docs[0].get('completed');
                              DatabaseManager()
                                  .updateUserModules(
                                      email: user?.email,
                                      modules: completed + 1)
                                  .then((_) {
                                if (completed + 1 == 2) {
                                  showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: const Text("Congratulations!"),
                                          content: const SingleChildScrollView(
                                              child: Text(
                                                  "You have unlocked your token multiplier for the day!")),
                                          actions: <Widget>[
                                            ElevatedButton(
                                                child: const Text("Ok"),
                                                onPressed: () {
                                                  DatabaseManager()
                                                      .updateUserMultiplier(
                                                          email: user?.email,
                                                          multiplier: 2)
                                                      .then((_) {
                                                    Navigator.of(context).pop();
                                                    Navigator.of(context).pop();
                                                  });
                                                })
                                          ],
                                        );
                                      });
                                } else {
                                  Navigator.of(context).pop();
                                }
                              });
                            });
                          }
                        },
                        child: Text(
                            (questionIndex.value + 1 <= 5) ? "Next" : "Finish",
                            style: const TextStyle(
                                backgroundColor: Colors.transparent))),
              ]),
            ])
          : const SizedBox(height: 0, width: 0),
      const SizedBox(height: 20),
      (!startStory.value)
          ? Column(children: [
              Container(
                  width: MediaQuery.of(context).size.width - 20,
                  height: MediaQuery.of(context).size.height / 4,
                  decoration: BoxDecoration(
                      color: Colors.lightBlue[50],
                      borderRadius:
                          const BorderRadius.all(Radius.circular(10))),
                  child: const Text(
                      "\nThis is the story about Henry, a parrot in the pet world, diagnosed with autism and the hardships as well as the positives it experienced throughout its life.  We learn how people with autism are affected from this story.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontFamily: "Raleway",
                          fontWeight: FontWeight.w400,
                          fontSize: 20))),
              const SizedBox(height: 20),
              ElevatedButton(
                  onPressed: () {
                    startStory.value = true;
                    displayQuestion.value = true;
                  },
                  child: Text(displayText.value)),
            ])
          : const SizedBox(height: 0, width: 0),
    ]);
  }
}
