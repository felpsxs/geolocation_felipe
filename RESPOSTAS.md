# Respostas da atividade

## Etapa 1 — interface fictícia

Mensagens programadas no console de depuração:

| Interação | Método | Mensagem |
| --- | --- | --- |
| Botão Add Waypoint | `adicionarWaypoint()` | `Voce clicou no botão Add Waypoint` |
| Toque longo em um item | `navegarPara()` | `Voce acionou o Navegar para <nome>` |
| Botão STOP | `pararNavegacao()` | `Voce parou o Navegar para <nome>` |
| Deslizar um item | `excluirWaypoint()` | `Voce acionou o excluir Waypoint <nome>` |

Essas mensagens foram identificadas no código. A interação manual em emulador/dispositivo depende de um ambiente Android ou iOS configurado.

Métodos que retornam `Widget`:

| Método | Componentes e função |
| --- | --- |
| `KGpsLocatorApp.build()` | Retorna `MaterialApp`, a raiz da aplicação, com título e página inicial. |
| `_HomePageState.build()` | Retorna `Scaffold`, com `AppBar`, corpo, botão STOP condicional e botão inferior. `SafeArea` evita áreas do sistema; `Column` organiza na vertical; `Expanded` entrega o espaço restante à lista. |
| `_buildLocationInfo()` | Retorna cartão com latitude, longitude e altitude. `Padding` cria espaço interno ou externo; `EdgeInsets.symmetric(horizontal: 16)` aplica 16 pontos à esquerda e à direita. |
| `_buildNavigationInfo()` | Retorna cartão de navegação com o waypoint selecionado e campos ainda fictícios de azimute e distância. |
| `_buildWaypointList()` | Retorna `ListView.builder`, que monta cada item sob demanda. `Dismissible` reconhece o gesto de deslizar; `ListTile` mostra nome e coordenadas e recebe toque longo. |
| `_infoRow()` | Retorna uma linha com rótulo e valor. `MainAxisAlignment.spaceBetween` os coloca em extremidades opostas. |
| `Compass.build()` | Retorna `SizedBox` de 280 × 280 com `CustomPaint`, que chama `CompassPainter` para desenhar a bússola. |

`EdgeInsets.symmetric` cria espaçamento igual em lados opostos: `horizontal` controla esquerda e direita; `vertical`, cima e baixo.

## Etapa 2 — tipos de heading

`double heading = 0;` não aceita `null` e começa em zero. `double? heading;` aceita `null`, útil quando ainda não chegou uma leitura do sensor. O material escreve `Heading` com maiúscula no segundo exemplo; em Dart, esse seria outro identificador, pois a linguagem diferencia maiúsculas e minúsculas.
