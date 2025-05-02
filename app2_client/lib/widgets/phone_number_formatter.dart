import 'package:flutter/services.dart';

class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    // 백스페이스 등으로 길이가 줄어들었는지 확인
    bool isErasing = oldValue.text.length > newValue.text.length;

    final buffer = StringBuffer();
    int selectionIndex = newValue.selection.end;

    for (int i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      // 하이픈 추가 위치
      if (i == 2 || i == 6) {
        buffer.write('-');
        if (i < digits.length - 1 && i < selectionIndex) {
          // 커서 위치 보정: 하이픈이 삽입된 만큼 뒤로 밀림
          selectionIndex++;
        }
      }
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: selectionIndex > formatted.length ? formatted.length : selectionIndex,
      ),
    );
  }
}