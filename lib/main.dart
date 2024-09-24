import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:file_picker/file_picker.dart';

import 'package:image/image.dart' as img;

import 'package:media_kit/media_kit.dart'; // Provides [Player], [Media], [Playlist] etc.
import 'package:media_kit_video/media_kit_video.dart';

import 'audio_video_progress_bar.dart';

import 'dart:io';
import 'dart:core';

import 'package:path/path.dart' as path;
import 'package:window_size/window_size.dart';
import 'package:shared_preferences/shared_preferences.dart';

late SharedPreferences prefs;

void main() async {
  MediaKit.ensureInitialized();

  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    setWindowTitle('Video/Photo cropper');
    setWindowMinSize(const Size(700, 500));
  }

  prefs = await SharedPreferences.getInstance();

  runApp(const VideoApp());
}

class VideoApp extends StatelessWidget {
  const VideoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFD4AF37)),
        useMaterial3: true,
      ),
      home: const UploadPage(),
    );
  }
}

File? chosen_file;

BuildContext? context_;

void onUpload() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles();

  if (result != null) {
    chosen_file = File(result.files[0].path!);

    String ext =
        path.extension(chosen_file!.path).toLowerCase().replaceFirst('.', '');

    if (ext == "png" || ext == "jpg" || ext == "jpeg" || ext == "bmp") {
      if (context_ != null) {
        Navigator.push(
            context_!,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  VideoPage(
                photo_mode: true,
              ),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                const begin = Offset(-1.0, 0.0);
                const end = Offset.zero;
                const curve = Curves.easeInOut;

                var tween = Tween(begin: begin, end: end)
                    .chain(CurveTween(curve: curve));

                return SlideTransition(
                  position: animation.drive(tween),
                  child: child,
                );
              },
            ));
      }
    } else if (ext == "mp4") {
      if (context_ != null) {
        Navigator.push(
            context_!,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  VideoPage(photo_mode: false),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                const begin = Offset(-1.0, 0.0);
                const end = Offset.zero;
                const curve = Curves.easeInOut;

                var tween = Tween(begin: begin, end: end)
                    .chain(CurveTween(curve: curve));

                return SlideTransition(
                  position: animation.drive(tween),
                  child: child,
                );
              },
            ));
      }
    } else {
      showDialog(
          context: context_!,
          builder: (context) {
            return AlertDialog(
              icon: const Icon(Icons.error),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                      "Only .mp4, .jpg, .png and .bmp files are compatible"),
                  const SizedBox(
                    height: 25,
                  ),
                  ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text("OK")),
                ],
              ),
            );
          });
    }
  }
}

class UploadPage extends StatelessWidget {
  const UploadPage({super.key});

  @override
  Widget build(BuildContext context) {
    context_ = context;
    return Container(
      color: Colors.white,
      child: const Column(
        children: [
          Spacer(),
          IconButton(
              onPressed: onUpload,
              color: Color(0xFFD4AF37),
              iconSize: 100,
              icon: Icon(Icons.upload_file)),
          Spacer(),
        ],
      ),
    );
  }
}

class RepeatButton extends StatelessWidget {
  const RepeatButton({super.key, this.repeat, this.parent});

  final bool? repeat;
  final _VideoPageState? parent;

  @override
  Widget build(BuildContext context) {
    if (repeat == false) {
      return IconButton(
        onPressed: () {
          parent!.repeat = true;
          parent!.setState(() {});
        },
        icon: const Icon(
          Icons.repeat,
          color: Color(0xFFD4AF37),
        ),
        tooltip: "Turn Loop On",
      );
    } else {
      return IconButton(
        onPressed: () {
          parent!.repeat = false;
          parent!.setState(() {});
        },
        icon: const Icon(
          Icons.repeat_on,
          color: Color(0xFFD4AF37),
        ),
        tooltip: "Turn Loop Off",
      );
    }
  }
}

class PlayPauseButton extends StatelessWidget {
  const PlayPauseButton({super.key, this.playing, this.parent});

  final bool? playing;
  final _VideoPageState? parent;

  @override
  Widget build(BuildContext context) {
    if (playing == false) {
      return IconButton(
        onPressed: () {
          parent!.video_player.play();
          parent!.setState(() {});
        },
        icon: const Icon(Icons.play_arrow, color: Color(0xFFD4AF37)),
        tooltip: "Play",
      );
    } else {
      return IconButton(
        onPressed: () {
          parent!.video_player.pause();
          parent!.setState(() {});
        },
        icon: const Icon(Icons.pause, color: Color(0xFFD4AF37)),
        tooltip: "Pause",
      );
    }
  }
}

class HideShowButton extends StatelessWidget {
  const HideShowButton({super.key, this.showing, this.parent});

  final bool? showing;
  final _VideoPageState? parent;

  @override
  Widget build(BuildContext context) {
    if (showing == false) {
      return IconButton(
        onPressed: () {
          parent!.showing = true;

          double orig_width = MediaQuery.of(context).size.width;
          double orig_height =
              MediaQuery.of(context).size.height - parent!.bottom_bar_height;

          double base_offset_x = (orig_width / 2) - (parent!.sliver_width / 2);
          double base_offset_y =
              (orig_height / 2) - (parent!.sliver_height / 2);

          parent!.x_offset += base_offset_x;
          parent!.y_offset += base_offset_y;

          parent!.setState(() {});
        },
        icon: const Icon(Icons.visibility, color: Color(0xFFD4AF37)),
        tooltip: "Show full video",
      );
    } else {
      return IconButton(
        onPressed: () {
          parent!.showing = false;

          double orig_width = MediaQuery.of(context).size.width;
          double orig_height =
              MediaQuery.of(context).size.height - parent!.bottom_bar_height;

          double base_offset_x = (orig_width / 2) - (parent!.sliver_width / 2);
          double base_offset_y =
              (orig_height / 2) - (parent!.sliver_height / 2);

          parent!.x_offset -= base_offset_x;
          parent!.y_offset -= base_offset_y;

          parent!.setState(() {});
        },
        icon: const Icon(Icons.visibility_off, color: Color(0xFFD4AF37)),
        tooltip: "Only marked area",
      );
    }
  }
}

class ZoomInButton extends StatelessWidget {
  const ZoomInButton({super.key, this.parent});

  final _VideoPageState? parent;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        double amount = 0.1;

        if (RawKeyboard.instance.keysPressed
            .contains(LogicalKeyboardKey.shiftLeft)) {
          amount = 0.02;
        }

        parent!.scale = parent!.scale + amount;
        parent!.setState(() {});
      },
      icon: const Icon(Icons.zoom_in, color: Color(0xFFD4AF37)),
      tooltip: "Zoom In",
    );
  }
}

class ZoomOutButton extends StatelessWidget {
  const ZoomOutButton({super.key, this.parent});

  final _VideoPageState? parent;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        double amount = 0.1;

        if (RawKeyboard.instance.keysPressed
            .contains(LogicalKeyboardKey.shiftLeft)) {
          amount = 0.02;
        }

        parent!.scale = parent!.scale - amount;
        parent!.setState(() {});
      },
      icon: const Icon(Icons.zoom_out, color: Color(0xFFD4AF37)),
      tooltip: "Zoom Out",
    );
  }
}

class RotateCWButton extends StatelessWidget {
  const RotateCWButton({super.key, this.parent});

  final _VideoPageState? parent;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        parent!.quarter_turns = parent!.quarter_turns + 1;
        if (parent!.quarter_turns > 3) parent!.quarter_turns = 0;
        double x_rotate_offset =
            parent!.video_width / 2 - parent!.video_height / 2;
        double y_rotate_offset = x_rotate_offset;

        if (parent!.quarter_turns == 0 || parent!.quarter_turns == 2) {
          parent!.x_offset += x_rotate_offset;
          parent!.y_offset -= y_rotate_offset;
        } else if (parent!.quarter_turns == 1 || parent!.quarter_turns == 3) {
          parent!.x_offset += x_rotate_offset;
          parent!.y_offset -= y_rotate_offset;
        }

        parent!.setState(() {});
      },
      icon: const Icon(Icons.rotate_right, color: Color(0xFFD4AF37)),
      tooltip: "Rotate 90° Clockwise",
    );
  }
}

class RotateCCWButton extends StatelessWidget {
  const RotateCCWButton({super.key, this.parent});

  final _VideoPageState? parent;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        parent!.quarter_turns = parent!.quarter_turns - 1;
        if (parent!.quarter_turns < 0) parent!.quarter_turns = 3;

        double x_rotate_offset =
            parent!.video_width / 2 - parent!.video_height / 2;
        double y_rotate_offset = x_rotate_offset;

        if (parent!.quarter_turns == 0 || parent!.quarter_turns == 2) {
          parent!.x_offset += x_rotate_offset;
          parent!.y_offset -= y_rotate_offset;
        } else if (parent!.quarter_turns == 1 || parent!.quarter_turns == 3) {
          parent!.x_offset += x_rotate_offset;
          parent!.y_offset -= y_rotate_offset;
        }
        parent!.setState(() {});
      },
      icon: const Icon(Icons.rotate_left, color: Color(0xFFD4AF37)),
      tooltip: "Rotate 90° Counter-Clockwise",
    );
  }
}

class FolderButton extends StatelessWidget {
  FolderButton({super.key, this.parent});

  final _VideoPageState? parent;

  void dialogSetState() {}

  @override
  Widget build(BuildContext context) {
    TextEditingController photo_controller =
        TextEditingController(text: parent!.target_pic_folder);
    TextEditingController video_controller =
        TextEditingController(text: parent!.target_video_folder);

    return IconButton(
      onPressed: () async {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return StatefulBuilder(builder: (context, dialogSetState) {
              return AlertDialog(
                title: const Text("Folder Settings"),
                content: SizedBox(
                  width: 500,
                  height: 220,
                  child: Column(children: [
                    const Text("Saving Images in: "),
                    Row(
                      children: [
                        SizedBox(
                            width: 450,
                            height: 60,
                            child: TextField(
                                controller: photo_controller,
                                onChanged: (text) async {
                                  bool exists = await Directory(text).exists();
                                  if (exists) {
                                    parent!.target_pic_folder = text;
                                    parent!.setState(() {});
                                  }
                                })),
                        IconButton(
                          onPressed: () async {
                            String? path =
                                await FilePicker.platform.getDirectoryPath();
                            if (path != null) {
                              photo_controller.text = path;
                              parent!.target_pic_folder = path;
                            }

                            parent!.setState(() {});
                          },
                          icon: const Icon(Icons.drive_folder_upload,
                              color: Color(0xFFD4AF37)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text("Saving Videos in: "),
                    Row(
                      children: [
                        SizedBox(
                            width: 450,
                            height: 60,
                            child: TextField(
                                controller: video_controller,
                                onChanged: (text) async {
                                  bool exists = await Directory(text).exists();
                                  if (exists) {
                                    parent!.target_video_folder = text;
                                    parent!.setState(() {});
                                  }
                                })),
                        IconButton(
                          onPressed: () async {
                            String? path =
                                await FilePicker.platform.getDirectoryPath();
                            if (path != null) {
                              video_controller.text = path;
                              parent!.target_video_folder = path;
                            }
                            parent!.setState(() {});
                          },
                          icon: const Icon(Icons.drive_folder_upload,
                              color: Color(0xFFD4AF37)),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    Row(
                      children: [
                        const Text("Open folder after saving: "),
                        const SizedBox(width: 5),
                        Checkbox(
                            value: parent!.open_folder_after_saving,
                            onChanged: (value) {
                              parent!.open_folder_after_saving = value!;
                              prefs.setBool("open_folder_after",
                                  parent!.open_folder_after_saving);
                              dialogSetState(() {});
                            }),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            parent!.setState(() {});
                          },
                          child: const Text("Confirm"),
                        ),
                      ],
                    ),
                  ]),
                ),
              );
            });
          },
        ).then((val) {
          prefs.setString('target_pic_folder', parent!.target_pic_folder);
          prefs.setString('target_video_folder', parent!.target_video_folder);
        });
        parent!.setState(() {});
      },
      icon: const Icon(Icons.drive_folder_upload, color: Color(0xFFD4AF37)),
      tooltip: "Change target save folder",
    );
  }
}

class SaveButton extends StatelessWidget {
  const SaveButton({super.key, this.saving, this.parent});

  final _VideoPageState? parent;
  final bool? saving;

  @override
  Widget build(BuildContext context) {
    if (saving == false) {
      return IconButton(
        onPressed: () async {
          String folder;
          print(parent!.mark_end - parent!.mark_start);
          if (((parent!.mark_end - parent!.mark_start <=
                      const Duration(seconds: 9)) ||
                  (parent!.mark_end - parent!.mark_start >
                      const Duration(seconds: 51))) &&
              parent!.widget.photo_mode == false) {
            showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    icon: const Icon(Icons.error),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                            "Please keep the videos between 10 and 50 seconds"),
                        const SizedBox(
                          height: 25,
                        ),
                        ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text("OK")),
                      ],
                    ),
                  );
                });
            return;
          }

          if (parent!.widget.photo_mode) {
            folder = parent!.target_pic_folder;
          } else {
            folder = parent!.target_video_folder;
          }
          if (!folder.endsWith(path.separator)) {
            folder += path.separator;
          }

          parent!.is_saving = true;

          String save_file_path = "";

          if (parent!.widget.photo_mode) {
            for (var i = 0; i < 1000; i++) {
              save_file_path = path.join(folder,
                  "${parent!.default_pic_title}${i.toString().padLeft(4, "0")}.jpg");
              if (File(save_file_path).existsSync()) {
                continue;
              } else {
                break;
              }
            }
          } else {
            for (var i = 0; i < 100; i++) {
              save_file_path = path.join(folder,
                  "${parent!.default_video_title}${i.toString().padLeft(2, "0")}.MP4");

              if (File(save_file_path).existsSync()) {
                continue;
              } else {
                break;
              }
            }
          }

          String timestamp = "";
          if (!parent!.widget.photo_mode) {
            int mili = parent!.mark_start.inMilliseconds % 1000;
            int secs_full = parent!.mark_start.inMilliseconds ~/ 1000;
            int secs = secs_full % 60;
            int min_full = secs_full ~/ 60;
            int min = min_full % 60;
            int hour_full = min_full ~/ 60;
            int hour = hour_full % 24;

            timestamp =
                "${hour.toString().padLeft(2, "0")}:${min.toString().padLeft(2, "0")}:${secs.toString().padLeft(2, "0")}.${mili.toString().padLeft(3, "0")}0";
          }

          String transpose_str = "";

          for (int i = 0; i < parent!.quarter_turns; i++) {
            transpose_str += "transpose=1";
            transpose_str += ",";
          }

          var scaleWidth =
              parent!.sliver_width_px / parent!.orig_video_width_px;
          var scaleHeight =
              parent!.sliver_height_px / parent!.orig_video_height_px;

          var scale = max(scaleWidth, scaleHeight);

          // double outW = parent!.sliver_width_px / parent!.scale;
          // double outH = parent!.sliver_height_px / parent!.scale;

          double out_w = parent!.sliver_width_px / scale;
          double out_h = parent!.sliver_height_px / scale;

          double sliver_x =
              (parent!.viewport_width / 2) - (parent!.sliver_width / 2);
          double sliver_y =
              (parent!.viewport_height / 2) + (parent!.sliver_height / 2);

          double offset_to_tl_x = sliver_x - parent!.x_offset;
          double offset_to_tl_y =
              (parent!.y_offset + parent!.video_height) - sliver_y;

          double? x;
          double? y;

          if (parent!.quarter_turns == 0 || parent!.quarter_turns == 2) {
            x = (offset_to_tl_x / parent!.video_width) *
                parent!.orig_video_width_px;
            y = (offset_to_tl_y / parent!.video_height) *
                parent!.orig_video_height_px;
          } else if (parent!.quarter_turns == 1 || parent!.quarter_turns == 3) {
            x = (offset_to_tl_x / parent!.video_width) *
                parent!.orig_video_height_px;
            y = (offset_to_tl_y / parent!.video_height) *
                parent!.orig_video_width_px;
          }

          transpose_str +=
              "crop=${out_w.toInt()}:${out_h.toInt()}:${x!.toInt()}:${y!.toInt()},";
          transpose_str += "scale=960:192";

          if (parent!.widget.photo_mode) {
            double angle = 90.0 * parent!.quarter_turns;

            img.Image rotated_image =
                img.copyRotate(parent!.orig_photo!, angle: angle);
            img.Image cropped_image = img.copyCrop(rotated_image,
                x: x.toInt(),
                y: y.toInt(),
                width: out_w.toInt(),
                height: out_h.toInt());
            img.Image scaled_image =
                img.copyResize(cropped_image, width: 960, height: 192);

            Future<bool> result =
                img.encodeImageFile(save_file_path, scaled_image);

            result.then((result) {
              parent!.is_saving = false;
              parent!.id_entry.text =
                  (int.parse(parent!.id_entry.text) + 1).toString();
              if (parent!.open_folder_after_saving) {
                if (Platform.isMacOS) {
                  Process.run('open', [folder]).then((result) {
                    if (result.exitCode == 0) {
                      print('Folder opened successfully');
                    } else {
                      print('Failed to open folder: ${result.stderr}');
                    }
                  });
                } else {
                  Process.run("explorer.exe", [
                    folder,
                  ]);
                }
              }
              parent!.setState(() {});
            });
          } else {
            try {
              var tempFile = File(path.join(folder, 'temp.mp4'));
              if (tempFile.existsSync()) {
                tempFile.deleteSync(recursive: true);
              }
              var _7zLocationMac = r'assets/mac/';

              Future<ProcessResult> result_ = Platform.isMacOS
                  ? Process.run(
                      "./ffmpeg",
                      [
                        "-ss",
                        timestamp,
                        "-i",
                        chosen_file!.path,
                        "-t",
                        ((parent!.mark_end.inMilliseconds -
                                    parent!.mark_start.inMilliseconds) /
                                1000.0)
                            .toString(),
                        "-vf",
                        transpose_str,
                        "-an",
                        "-r",
                        "60",
                        (path.join(folder, 'temp.mp4')),
                      ],
                      workingDirectory: kReleaseMode
                          ? "/Applications/videoapp.app/Contents/$_7zLocationMac"
                          : _7zLocationMac)
                  : Process.run("assets/ffmpeg/ffmpeg-2.exe", [
                      "-ss",
                      timestamp,
                      "-i",
                      chosen_file!.path!,
                      "-t",
                      ((parent!.mark_end.inMilliseconds -
                                  parent!.mark_start.inMilliseconds) /
                              1000.0)
                          .toString(),
                      "-vf",
                      transpose_str,
                      "-an",
                      "./temp.mp4",
                    ]);

              result_.then((pro_result) {
                print(pro_result.stderr);
                print(pro_result.stdout);

                print(
                    "here2 $save_file_path ${path.join(parent!.default_video_title, 'temp.mp4')}");
                Future<ProcessResult> result = Platform.isMacOS
                    ? Process.run(
                        "./ffmpeg",
                        [
                          "-i",
                          (path.join(folder, 'temp.mp4')),
                          "-vcodec",
                          "libx264",
                          "-c:v",
                          "libx264",
                          "-bsf:v",
                          "h264_mp4toannexb",
                          "-f",
                          "mpegts",
                          save_file_path,
                        ],
                        workingDirectory: kReleaseMode
                            ? "/Applications/videoapp.app/Contents/$_7zLocationMac"
                            : _7zLocationMac)
                    : Process.run("assets/ffmpeg/ffmpeg.exe", [
                        "-i",
                        "./temp.mp4",
                        "-c:v",
                        "copy",
                        "-bsf:v",
                        "h264_mp4toannexb",
                        save_file_path,
                      ]);
                result.then((pro_result2) {
                  try {
                    File file = File("./temp.mp4");

                    file.deleteSync();
                  } catch (e) {
                    //
                  }

                  print(pro_result2.stderr);
                  print(pro_result2.stdout);
                  parent!.is_saving = false;
                  parent!.id_entry.text =
                      (int.parse(parent!.id_entry.text) + 1).toString();
                  if (parent!.open_folder_after_saving) {
                    if (Platform.isMacOS) {
                      Process.run('open', [folder]).then((result) {
                        if (result.exitCode == 0) {
                          print('Folder opened successfully');
                        } else {
                          print('Failed to open folder: ${result.stderr}');
                        }
                      });
                    } else {
                      Process.run("explorer.exe", [
                        folder,
                      ]);
                    }
                  }
                  parent!.setState(() {});
                }).catchError((error, st) {
                  print("dad1212s>>> $error $st");
                });
              }).catchError((error, st) {
                print("dads>>> $error $st");
              });
            } catch (es, st) {
              print("EXcpeiont>>> $es $st");
            }
          }
          parent!.setState(() {});
        },
        icon: const Icon(
          Icons.save,
          color: Color(0xFFD4AF37),
        ),
        tooltip: "Save",
      );
    } else {
      return const CircularProgressIndicator();
    }
  }
}

class VideoPage extends StatefulWidget {
  VideoPage({super.key, required this.photo_mode});

  bool photo_mode;

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  img.Image? orig_photo;

  double x_offset = 0;
  double y_offset = 0;

  Duration mark_start = Duration.zero;
  Duration mark_end = Duration.zero;

  String default_video_title = "FILE200101-0811";
  String default_pic_title = "IMG200101-08";

  String target_video_folder = "";
  String target_pic_folder = "";

  double viewport_width = 10;
  double viewport_height = 10;

  bool is_saving = false;

  int bottom_bar_height = 200;

  late TextEditingController id_entry;

  int orig_video_width_px = 1;
  int orig_video_height_px = 1;

  int quarter_turns = 0;

  double video_width = 800;
  double video_height = 10;

  double sliver_width = 10;
  double sliver_height = 10;

  double relative_sliver_width = 0;
  double relative_sliver_height = 0;

  double scale = 1.0;

  bool open_folder_after_saving = prefs.getBool("open_folder_after") ?? true;
  bool showing = true;
  bool repeat = false;

  final double sliver_width_px = 960;
  final double sliver_height_px = 192;

  late final video_player =
      Player(configuration: const PlayerConfiguration(osc: false));
  late final video_controller = VideoController(video_player);

  @override
  void dispose() {
    video_player.dispose();
    super.dispose();
  }

  void setupViewport() async {
    if (widget.photo_mode) {
      img.Image? image = await img.decodeImageFile(
          chosen_file!.path); // Or any other way to get a File instance
      orig_photo = image;

      orig_video_width_px = image!.width;
      orig_video_height_px = image.height;

      mark_end = video_controller.player.state.duration;

      video_width = 800;
      video_height = video_width * orig_video_height_px / orig_video_width_px;

      double sliver_scale = video_width / orig_video_width_px;

      sliver_width = sliver_width_px * sliver_scale;
      sliver_height = sliver_height_px * sliver_scale;

      x_offset = (viewport_width / 2 - video_width / 2);
      y_offset = (viewport_height / 2 - video_height / 2);

      setState(() {});
    } else {
      Media media = Media(chosen_file!.path);
      await video_player.open(media);

      video_player.stream.videoParams.listen((VideoParams params) {
        orig_video_width_px = params.w!;
        orig_video_height_px = params.h!;

        mark_end = video_controller.player.state.duration;

        video_width = 800;
        video_height = video_width * orig_video_height_px / orig_video_width_px;

        double sliver_scale = video_width / orig_video_width_px;

        sliver_width = sliver_width_px * sliver_scale;
        sliver_height = sliver_height_px * sliver_scale;

        x_offset = (viewport_width / 2 - video_width / 2);
        y_offset = (viewport_height / 2 - video_height / 2);

        setState(() {});
      });
    }
  }

  void updateViewportSize() async {
    if (quarter_turns == 0 || quarter_turns == 2) {
      video_width = 800 * scale;
      video_height = (video_width * orig_video_height_px / orig_video_width_px);
    } else if (quarter_turns == 1 || quarter_turns == 3) {
      video_height = 800 * scale;
      video_width = (video_height * orig_video_height_px / orig_video_width_px);
    }
  }

  @override
  void initState() {
    super.initState();
    id_entry = TextEditingController(text: "0");

    setupViewport();

    String folder;

    // int name_length = chosen_file!.name!.length;
    folder = path.dirname(chosen_file!.path);

    if (prefs.getString('target_pic_folder') != null) {
      target_pic_folder = prefs.getString('target_pic_folder')!;
    } else {
      target_pic_folder = folder;
      prefs.setString('target_pic_folder', folder);
    }

    if (prefs.getString('target_video_folder') != null) {
      target_video_folder = prefs.getString('target_video_folder')!;
    } else {
      target_video_folder = folder;
      prefs.setString('target_video_folder', folder);
    }

    video_player.stream.position.listen((position) {
      if (position <= mark_start) {
        video_player.seek(mark_start);
        setState(() {});
      }

      Duration end_marker_fix = Duration.zero;

      if (mark_end >= video_player.state.duration) {
        end_marker_fix = const Duration(milliseconds: 200);
      }

      if (position >= mark_end - end_marker_fix) {
        if (!repeat) {
          video_player.pause();
          video_player.seek(mark_start);
        } else {
          video_player.seek(mark_start);
        }
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showing) {
      viewport_width = MediaQuery.of(context).size.width;
      viewport_height = MediaQuery.of(context).size.height - bottom_bar_height;
    } else {
      viewport_width = sliver_width;
      viewport_height = sliver_height;
    }

    updateViewportSize();

    Container viewport_stack = Container(
        width: viewport_width,
        height: viewport_height,
        child: Stack(children: <Widget>[
          Container(color: Colors.white),
          Positioned(
            bottom: y_offset,
            left: x_offset,
            child: SizedBox(
              width: video_width,
              height: video_height,
              child: RotatedBox(
                quarterTurns: quarter_turns,
                child: Visibility(
                  visible: !widget.photo_mode,
                  replacement: Image.file(
                    File(chosen_file!.path),
                    fit: BoxFit.fill,
                  ),
                  child: Video(
                    controller: video_controller,
                    controls: NoVideoControls,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: (viewport_height / 2) - (sliver_height / 2),
            left: (viewport_width / 2) - (sliver_width / 2),
            child: SizedBox(
              width: sliver_width,
              height: sliver_height,
              child: const Image(image: AssetImage("assets/frame.png")),
            ),
          ),
        ]));

    return Scaffold(
      body: Column(
        children: [
          GestureDetector(
            child: Visibility(
              visible: showing,
              replacement: Container(
                height: MediaQuery.of(context).size.height - bottom_bar_height,
                color: Colors.white,
                child: Center(
                  child: viewport_stack,
                ),
              ),
              child: viewport_stack,
            ),
            onPanUpdate: (details) {
              y_offset = y_offset - details.delta.dy;
              x_offset = x_offset + details.delta.dx;
              setState(() {});
            },
          ),
          Visibility(
            visible: !widget.photo_mode,
            replacement: const SizedBox(height: 50),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(200.0, 25, 200.0, 25),
                child: StreamBuilder(
                  stream: video_controller.player.stream.position,
                  builder: (context, snapshot) {
                    final duration = snapshot.data;

                    final progress = duration ?? Duration.zero;
                    final total = video_player.state.duration;

                    return ProgressBar(
                        progress: progress,
                        mark_start: mark_start,
                        mark_end: mark_end,
                        total: total,
                        baseBarColor: const Color.fromARGB(255, 100, 81, 19),
                        progressBarColor: const Color(0xFFD4AF37),
                        onMarkStartDragDrop: (duration) {
                          mark_start = duration;
                        },
                        onMarkEndDragDrop: (duration) {
                          mark_end = duration;
                        },
                        onSeek: (duration) {
                          video_player.seek(duration);
                        });
                  },
                ),
              ),
            ),
          ),
          Center(
              child: Row(
            children: [
              const Spacer(),
              Visibility(
                visible: !widget.photo_mode,
                child: PlayPauseButton(
                  playing: video_player.state.playing,
                  parent: this,
                ),
              ),
              Visibility(
                visible: !widget.photo_mode,
                child: RepeatButton(
                  repeat: repeat,
                  parent: this,
                ),
              ),
              HideShowButton(showing: showing, parent: this),
              const SizedBox(width: 35),
              ZoomInButton(
                parent: this,
              ),
              ZoomOutButton(
                parent: this,
              ),
              const SizedBox(width: 35),
              RotateCCWButton(
                parent: this,
              ),
              RotateCWButton(
                parent: this,
              ),
              const SizedBox(width: 35),
              FolderButton(parent: this),
              SaveButton(
                parent: this,
                saving: is_saving,
              ),
              const SizedBox(width: 35),
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.exit_to_app, color: Color(0xFFD4AF37)),
                tooltip: "Choose another file.",
              ),
              const Spacer(),
            ],
          ))
        ],
      ),
    );
  }
}
