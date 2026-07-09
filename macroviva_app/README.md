# MacroViva Mobile

Aplicativo Flutter do MacroViva. A fundacao mobile usa Riverpod, go_router e Dio para consumir a API local do backend.

## Stack

- Flutter
- Dart
- Dio
- Riverpod
- go_router
- camera e image_picker preparados para etapa futura

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

Android Emulator:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5169
```

Fallback de desenvolvimento, quando `API_BASE_URL` nao for informado:

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

`POST /api/meals` envia `mealType` como string, por exemplo `"Lunch"`, e cada item contem apenas `foodId` e `grams`, conforme o contrato atual do backend.

## Escopo atual

Incluido nesta etapa:

- app root com `ProviderScope`;
- roteamento inicial com go_router;
- tema simples;
- Dio central com timeout e logs em debug;
- configuracao `API_BASE_URL`;
- dashboard com refeicoes do dia e resumo de macros;
- lista de alimentos usando `GET /api/foods`;
- lista de suplementos e check-in;
- criacao manual de refeicao;
- teste basico de renderizacao.

Fora desta etapa:

- autenticacao real;
- pagamentos;
- chamada direta a OpenAI;
- camera/upload completo;
- analise de foto por IA;
- autenticacao real;
- pagamentos.
