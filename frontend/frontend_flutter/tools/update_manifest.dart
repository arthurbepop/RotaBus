import 'dart:io';

void main() async {
  final envFile = File('.env');
final manifestFile = File('android/app/src/main/AndroidManifest.xml');

  if (!envFile.existsSync() || !manifestFile.existsSync()) {
    print('Arquivo .env ou AndroidManifest.xml não encontrado.');
    exit(1);
  }

  final envContent = await envFile.readAsLines();
  final apiKeyLine = envContent.firstWhere(
    (line) => line.startsWith('GOOGLE_MAPS_API_KEY='),
    orElse: () => '',
  );
  if (apiKeyLine.isEmpty) {
    print('GOOGLE_MAPS_API_KEY não encontrada no .env');
    exit(1);
  }
  final apiKey = apiKeyLine.split('=')[1];

  final manifestContent = await manifestFile.readAsString();
  final updatedManifest = manifestContent.replaceAllMapped(
    RegExp(r'(<meta-data android:name="com\.google\.android\.geo\.API_KEY"\s+android:value=")[^"]*(")'),
    (match) => '${match.group(1)}$apiKey${match.group(2)}',
  );

  await manifestFile.writeAsString(updatedManifest);
  print('AndroidManifest.xml atualizado com a chave do .env!');
}