import 'package:flutter_test/flutter_test.dart';
import 'package:bourse_agricole_web/main.dart';

void main() {
  testWidgets('Vérification du chargement de la BAN ITURI', (WidgetTester tester) async {
    // On appelle BourseAgricoleApp (défini dans main.dart)
    await tester.pumpWidget(const BourseAgricoleApp());

    // On vérifie que l'accueil s'affiche en cherchant un mot-clé
    // (Ajustez 'BAN ITURI' si le texte est différent dans votre accueil)
    expect(find.textContaining('BAN ITURI'), findsWidgets);
  });
}