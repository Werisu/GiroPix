import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:giropix/core/widgets/meta_batida_banner.dart';
import 'package:giropix/data/models/metas_diarias.dart';

AlvoMeta _alvo({required double meta, required double realizado}) {
  return AlvoMeta(
    titulo: 'Meta do dia',
    detalhe: 'Sex',
    meta: meta,
    realizado: realizado,
  );
}

void main() {
  test('cruzouAgora só na passagem da meta', () {
    final abaixo = _alvo(meta: 200, realizado: 150);
    final noAlvo = _alvo(meta: 200, realizado: 200);
    final acima = _alvo(meta: 200, realizado: 230);
    final aindaAbaixo = _alvo(meta: 200, realizado: 180);
    final semMeta = _alvo(meta: 0, realizado: 80);

    expect(noAlvo.cruzouAgora(abaixo), isTrue);
    expect(acima.cruzouAgora(abaixo), isTrue);
    expect(acima.cruzouAgora(noAlvo), isFalse);
    expect(aindaAbaixo.cruzouAgora(abaixo), isFalse);
    expect(acima.cruzouAgora(semMeta), isTrue);
    expect(semMeta.cruzouAgora(abaixo), isFalse);
  });

  testWidgets('banner da meta aparece no topo e some sozinho', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => MetaBatidaBanner.show(context),
              child: const Text('celebrar'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('celebrar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Meta batida'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2200));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Meta batida'), findsNothing);
  });
}
