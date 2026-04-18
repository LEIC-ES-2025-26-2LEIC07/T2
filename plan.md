# Plano de Implementacao: Notificacoes Reais de Medicacao em Falta

## Objetivo

Implementar notificacoes locais reais para alertar o utilizador quando uma toma agendada nao for registada dentro do periodo de graca definido.

## Estimativa

- Versao funcional local: 5 story points
- Versao robusta com sincronizacao e edge cases: 8 story points

## Escopo

### Incluido

- Integracao com `flutter_local_notifications`
- Pedido e validacao de permissoes
- Agendamento da notificacao primaria
- Agendamento da notificacao de toma em falta apos 30 minutos
- Cancelamento da notificacao em falta quando a dose for registada
- Deep-link para o ecra de registo da dose
- Validacao em Android e iOS

### Opcional

- Sincronizacao entre dispositivos
- Reagendamento apos reinicio do dispositivo ou da app
- Tratamento de timezone
- Melhor cobertura de testes e cenarios de falha

## Tarefas

### 1. Integrar plugin de notificacoes

- Adicionar `flutter_local_notifications` ao projeto
- Criar implementacao concreta de `LocalNotificationGateway`
- Inicializar o plugin no arranque da app

Estimativa: 1 SP

### 2. Configurar permissoes e comportamento por plataforma

- Pedir permissao de notificacoes no Android e iOS
- Configurar canais de notificacao no Android
- Garantir comportamento correto quando a permissao for negada

Estimativa: 1 SP

### 3. Implementar agendamento real

- Ligar o `MissedDoseNotificationController` ao plugin real
- Agendar notificacao primaria
- Agendar notificacao secundaria com ID deterministico
- Guardar payload para navegacao

Estimativa: 1 SP

### 4. Implementar cancelamento apos registo

- Cancelar notificacao pendente depois de inserir em `dose_logs`
- Garantir que `taken` e `skipped` cancelam corretamente
- Evitar notificacoes duplicadas

Estimativa: 1 SP

### 5. Deep-link e navegacao

- Abrir a app no ecra de registo da dose ao tocar na notificacao
- Destacar estado `overdue` no ecra
- Validar fluxo com app aberta, em background e fechada

Estimativa: 1 SP

## Extensoes Para 8 Story Points

### 6. Sincronizacao entre dispositivos

- Ao abrir a app, verificar `dose_logs` no Supabase
- Cancelar localmente notificacoes ja invalidadas noutro dispositivo

Estimativa: 1 SP

### 7. Resiliencia e edge cases

- Reagendar notificacoes apos reboot ou restart da app
- Tratar timezone e alteracoes de hora
- Cobrir permissoes negadas e falhas de agendamento

Estimativa: 1 SP

### 8. Testes e validacao final

- Testes unitarios da gateway concreta
- Testes de integracao do fluxo de toque na notificacao
- Checklist manual Android/iOS

Estimativa: 1 SP

## Dependencias

- Existencia de dados de dose e horario no modelo de medicacao
- Fluxo de registo de dose ligado ao `dose_logs`
- Acesso a dispositivos ou emuladores Android/iOS para validacao

## Definicao de Concluido

- A app agenda notificacoes reais no SO
- A notificacao de toma em falta dispara apenas se a dose nao for registada
- O registo da dose cancela a notificacao pendente
- Tocar na notificacao abre o ecra certo
- O fluxo foi validado pelo menos num dispositivo Android e num iOS, se ambos fizerem parte do escopo da equipa

## Ordem Recomendada

1. Integrar plugin e permissoes
2. Implementar agendamento real
3. Implementar cancelamento
4. Validar deep-link
5. Fechar sincronizacao e edge cases
6. Testar em dispositivos reais

## Nota

Este plano assume que a base logica ja criada no projeto sera reaproveitada e que falta sobretudo substituir a gateway `NoopLocalNotificationGateway` por uma implementacao real.
