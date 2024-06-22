import 'dart:math';

import 'package:chat_color/chat_color.dart';
import 'package:color/color.dart';

class PLogger {
  static List<String> modifiers = [];
  final String nodeName;
  final String _header;
  String get _fgc => trueColorTrigger;
  String get _bgc => trueColorBackgroundTrigger;

  PLogger(this.nodeName) : _header = "${nodeName.chatColor} ";

  void log(Object message, {String prefix = "", int indent = 0}) {
    print(
        "${modifiers.map((i) => i.chatColor).join("")}${indent > 0 ? " " * indent : ""}$_header${"$prefix$message".chatColor}");
  }

  void announcement(
      {required String msg,
      required String preformat,
      required Color tl,
      required Color tr,
      required Color bl,
      required Color br,
      bool clip = false,
      bool thick = false,
      bool fringes = false}) {
    List<String> message = msg.split("\n");

    if (message.last.trim().isEmpty) {
      message.removeLast();
    }

    message = message.map((String s) => s.trim()).toList();

    int vpad = 1 + (thick ? 1 : 0);
    int h = message.length + vpad * 2;
    int w = message.fold(
            0, (int prev, String element) => max(prev, element.length)) +
        6;
    w = w % 2 == 0 ? w + 1 : w;

    double d1len = 1 / h;
    double d1wid = 1 / w;
    HsvColor hsvtl = tl.toHsvColor();
    HsvColor hsvtr = tr.toHsvColor();
    HsvColor hsvbl = bl.toHsvColor();
    HsvColor hsvbr = br.toHsvColor();
    String m = "";
    print("");
    for (int i = 0; i < h; i++) {
      double ht = i * d1len;

      StringBuffer sb = StringBuffer();

      if (i > vpad - 1 && i < h - vpad) {
        m = "${" " * ((w - message[i - vpad].length) ~/ 2)}${message[i - vpad]}";
      }

      for (int j = 0; j < w; j++) {
        double wt = j * d1wid;

        HsvColor left = HsvColor(
          _lerp(hsvtl.h.toDouble(), hsvbl.h.toDouble(), ht),
          _lerp(hsvtl.s.toDouble(), hsvbl.s.toDouble(), ht),
          _lerp(hsvtl.v.toDouble(), hsvbl.v.toDouble(), ht),
        );

        HsvColor right = HsvColor(
          _lerp(hsvtr.h.toDouble(), hsvbr.h.toDouble(), ht),
          _lerp(hsvtr.s.toDouble(), hsvbr.s.toDouble(), ht),
          _lerp(hsvtr.v.toDouble(), hsvbr.v.toDouble(), ht),
        );

        HexColor c = HsvColor(
          _lerp(left.h.toDouble(), right.h.toDouble(), wt) % 360,
          _lerp(left.s.toDouble(), right.s.toDouble(), wt),
          _lerp(left.v.toDouble(), right.v.toDouble(), wt),
        ).toHexColor();

        if (fringes && (i == 0 || i + 1 == h) && j % 2 == 0) {
          c = Color.hex("#000000").toHexColor();
        }

        if (clip && ((i == 0 || i + 1 == h) && (j == 0 || j + 1 == w))) {
          c = Color.hex("#000000").toHexColor();
        }

        sb.write(
            "$_bgc(${c.toCssString()})${i > vpad - 1 && i < h - vpad && j < m.length ? m[j] == " " ? m[j] : "$preformat${m[j]}${j + 1 == m.length ? "&r" : ""}" : " "}");
      }

      print(sb.toString().chatColor);
    }
    print("");
  }

  void criticalAnnouncement(String msg) {
    announcement(
        msg: msg,
        fringes: true,
        thick: true,
        preformat: "&l&n&o&e",
        tl: Color.hex("#4a2c2c"),
        tr: Color.hex("#4a3b2c"),
        br: Color.hex("#4a492c"),
        bl: Color.hex("#4a422c"));
  }

  void noticeAnnouncement(String msg) {
    announcement(
        msg: msg,
        fringes: false,
        clip: true,
        preformat: "&l&o&b",
        tl: Color.hex("#2c404a"),
        tr: Color.hex("#2c364a"),
        br: Color.hex("#2c304a"),
        bl: Color.hex("#2f2c4a"));
  }

  void verbose(Object message, {int indent = 0}) =>
      log(message, prefix: "${_fgc}7", indent: indent);
  void info(Object message, {int indent = 0}) =>
      log(message, prefix: "${_fgc}f${_fgc}l", indent: indent);
  void warn(Object message, {int indent = 0}) =>
      log(message, prefix: "${_fgc}e${_fgc}l", indent: indent);
  void error(Object message, {int indent = 0}) =>
      log(message, prefix: "${_fgc}c${_fgc}l", indent: indent);
  void success(Object message, {int indent = 0}) =>
      log(message, prefix: "${_fgc}a${_fgc}l", indent: indent);
  void critical(Object message, {int indent = 0}) => log(message,
      prefix: "${_bgc}4${_fgc}f${_fgc}l${_fgc}n${_fgc}o", indent: indent);
  void notice(Object message, {int indent = 0}) =>
      log(message, prefix: "${_bgc}1${_fgc}b${_fgc}l", indent: indent);

  double _bilerp(double a, double b, double c, double d, double fx, double fy) {
    return _lerp(_lerp(a, b, fx), _lerp(c, d, fx), fy);
  }

  double _bilerpHue(
      double a, double b, double c, double d, double fx, double fy) {
    return _lerp(_lerpHue(a, b, fx), _lerpHue(c, d, fx), fy);
  }

  double _lerp(double a, double b, double f) => a + f * (b - a);

  double _lerpHue(double a, double b, double f) {
    double d = b - a;
    if (d > 180) {
      b -= 360;
    } else if (d < -180) {
      b += 360;
    }
    return _lerp(a, b, f) % 360;
  }
}
