# MacroViva Mobile

Aplicativo Flutter do MacroViva. A fundacao mobile usa Riverpod, go_router e Dio para consumir a API local do backend.

## Stack

- Flutter
- Dart
- Dio
- Riverpod
- go_router
- image_picker

## Backend local

No repositorio `macroviva-backend`, suba o SQL Server e rode a API:

```powershell
docker compose --env-file infra/.env.example -f infra/docker-compose.yml up -d
dotnet ef database update --project src/MacroViva.Infrastructure --startup-project src/MacroViva.Api
dotnet run --project src/MacroViva.Api --launch-profile http
```

URLs do backend:

```text
Health:  http://localhost:5169/health
Swagger: http://localhost:5169/swagger
```

## Base URL

A URL da API e configurada por `dart-define`.

Windows/Desktop:

```powershell
flutter run --dart-define=API_BASE_URL=http://localhost:5169
```

Chrome/Web:

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:5169
```

Android Emulator:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5169
```

Fallback de desenvolvimento, quando `API_BASE_URL` não for informado:

```text
http://localhost:5169
```

## Comandos

```powershell
flutter pub get
flutter analyze
flutter test
```

## Endpoints integrados

Nesta etapa o app consome a API REST local para:

- `GET /api/foods`
- `GET /api/foods/{id}`
- `GET /api/supplements`
- `GET /api/meals/today`
- `POST /api/meals`
- `POST /api/user-supplements/check-in`
- `POST /api/ai/meal-photo/analyze`
- `POST /api/ai/meal-photo/{analysisId}/confirm`

`POST /api/meals` envia `mealType` como string, por exemplo `"Lunch"`, e cada item contem apenas `foodId` e `grams`, conforme o contrato atual do backend.

O fluxo de foto usa IA mock do backend com `MockMealVisionAnalyzer`. O resultado pode não corresponder à imagem real; a IA real será uma etapa futura. O app envia `multipart/form-data` com campo `file` e `mealType` como `"Lunch"`, exibe os itens detectados, exige escolha de `selectedFoodId` real e confirma usando o `analysisItemId` retornado pela análise. O estado da tela de resultado é temporário via navegação; no MVP, refresh do navegador durante a revisão pode perder a análise em memória.

## Identidade anonima do beta privado

Em Staging, o app gera um UUID v4 anonimo por instalacao, persiste-o localmente
e o envia no header `X-MacroViva-Tester-Id`. Ele separa os registros de testers
sem coletar nome, e-mail ou telefone. Reinstalar o app ou limpar os dados do
site/dispositivo cria uma nova identidade e nao representa uma conta de usuario
nem autenticacao real.

## Nota de produto

A V1 valoriza a base nutricional existente: o usuário pode registrar alimentos, ajustar gramas e acompanhar proteína, calorias e macros sem depender de IA real. Mensagens como "Modo baixa fome" ou "GLP-1 friendly" são informativas e não substituem orientação médica ou nutricional.

## Escopo atual

Incluido nesta etapa:

- app root com `ProviderScope`;
- roteamento inicial com go_router;
- tema simples;
- Dio central com timeout e logs em debug;
- configuracao `API_BASE_URL`;
- dashboard com refeições do dia e resumo de macros;
- lista de alimentos usando `GET /api/foods`;
- lista de suplementos e check-in;
- criação manual de refeição;
- análise mock de foto de refeição com revisão antes de confirmar;
- teste basico de renderizacao.

Fora desta etapa:

- autenticacao real;
- pagamentos;
- chamada direta a OpenAI;
- OpenAI real.
