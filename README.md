# GiroPix

Controle financeiro offline para motoboys.

## Recursos

- Dashboard com resumo (Dia / Semana / Quinzena / Mês)
- Registro rápido de corridas e gastos
- Histórico com exclusão de lançamentos
- Persistência local com Hive (100% offline)
- Gráfico de ganhos dos últimos 7 dias (`fl_chart`)

## Como rodar

```bash
flutter pub get
flutter run
```

## Estrutura

```
lib/
  core/           # tema e utilitários
  data/           # models, Hive e repositórios
  providers/      # estado (Provider)
  features/       # telas por feature
```
