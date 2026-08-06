# GiroPix

Controle financeiro offline para motoboys. Registre corridas e gastos, acompanhe o lucro real e faça backup dos dados em JSON — tudo no celular, sem internet.

## Recursos

- **Dashboard** — resumo por Dia, Semana, Quinzena e Mês (bruto, gastos, lucro líquido real)
- **Gráfico** — evolução dos ganhos líquidos nos últimos 7 dias (`fl_chart`)
- **Registro rápido** — corridas (valor, taxa do app com % padrão, Pix/Dinheiro/Cartão) e gastos (combustível, alimentação, outros)
- **Histórico** — extrato cronológico com exclusão de lançamentos
- **Offline total** — persistência local com Hive
- **Backup JSON** — exportar e importar (substituir tudo ou mesclar)
- **Tema dark** com acentos neon (verde/azul Pix)

## Telas

| Tela | Descrição |
|------|-----------|
| Início | Resumo financeiro, filtro de período e gráfico |
| Lançar | Abas de corrida e gastos do dia |
| Histórico | Lista de corridas e gastos |
| Configurações | Backup, contatos do desenvolvedor (engrenagem no Início) |

## Stack

| Item | Tecnologia |
|------|------------|
| Framework | Flutter 3 / Dart 3 |
| Estado | Provider |
| Banco local | Hive + hive_flutter |
| Gráficos | fl_chart |
| Formatação BRL | intl |
| Backup | path_provider, share_plus, file_picker |
| Links | url_launcher |

## Como rodar

Pré-requisitos: [Flutter SDK](https://docs.flutter.dev/get-started/install) instalado e um dispositivo/emulador.

```bash
cd GiroPix
flutter pub get
flutter run
```

Para um aparelho específico:

```bash
flutter devices
flutter run -d <device_id>
```

### Windows (projeto em disco diferente do pub-cache)

Se o build Android falhar com erro de caches Kotlin (`different roots` / `Could not close incremental caches`), o projeto já inclui `kotlin.incremental=false` em `android/gradle.properties`. Se ainda falhar:

```bash
flutter clean
flutter pub get
flutter run
```

## Backup

1. Abra **Configurações** (ícone de engrenagem no Início).
2. **Exportar backup** — gera um `.json` e abre a tela de compartilhar (Drive, WhatsApp, Arquivos…).
3. **Importar backup** — escolha o arquivo e o modo:
   - **Substituir tudo** — limpa os dados atuais e restaura o arquivo (ideal ao trocar de celular).
   - **Mesclar** — unifica por `id` sem apagar o restante.

> Os dados ficam só no aparelho. Sem backup exportado, desinstalar o app apaga os lançamentos.

Formato do arquivo (resumo):

```json
{
  "version": 1,
  "app": "giropix",
  "exportedAt": "...",
  "settings": { "taxaPadraoPercent": 15.0 },
  "corridas": [],
  "gastos": []
}
```

## Estrutura do projeto

```
lib/
  core/               # tema, utilitários, constantes, widgets
  data/
    local/            # HiveService
    models/           # Corrida, Gasto, ResumoFinanceiro
    repositories/     # acesso às boxes
    services/         # BackupService (export/import JSON)
  providers/          # FinanceProvider
  features/
    dashboard/        # Início + widgets (filtro, cards, gráfico)
    registro/         # lançamento de corrida e gastos
    historico/        # extrato
    backup/           # configurações e backup
    home/             # shell com bottom navigation
  app.dart
  main.dart
```

## Modelos

**Corrida** — id, data/hora, valor bruto, forma de pagamento, taxa do app  
(valor líquido = bruto − taxa)

**Gasto** — id, data, combustível, alimentação, outros  
(total = soma das categorias)

**Lucro líquido real** = líquido das corridas − total de gastos (no período filtrado)

## Testes e análise

```bash
flutter analyze
flutter test
```

## Desenvolvedor

**Wellysson N Rocha**

- E-mail: [wellysson35@gmail.com](mailto:wellysson35@gmail.com)
- WhatsApp: [(63) 99230-4647](https://wa.me/5563992304647)
- LinkedIn: [wellyssonrocha-front-end](https://www.linkedin.com/in/wellyssonrocha-front-end)

## Licença

Projeto privado (`publish_to: 'none'`). Uso conforme combinado com o autor.
