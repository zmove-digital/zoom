# Site da ZMOVE / ZOOM

Site institucional e página de produto do aplicativo **ZOOM**, hospedado como
**GitHub Pages** a partir deste mesmo repositório (pasta `docs/`).

```
docs/
├── index.html                      # página inicial (produto, recursos, telas, FAQ)
├── politica-de-privacidade.html    # política de privacidade (exigida pela Google Play)
├── classificacao.html              # classificação de conteúdo (IARC + classificação indicativa)
├── site.webmanifest                # manifesto do PWA
├── favicon.svg
├── robots.txt / sitemap.xml
└── assets/
    ├── css/site.css
    ├── js/site.js
    ├── fonts/Poppins-*.ttf         # fontes locais (nenhuma requisição externa)
    └── img/                        # capturas de tela (WebP), ícones e artes da Play
```

## Publicar

1. No repositório, abra **Settings → Pages**.
2. Em **Build and deployment**, escolha **Deploy from a branch**.
3. Branch: `main` · pasta: `/docs` → **Save**.
4. O site fica disponível em `https://zmove-digital.github.io/zoom/`.

> Os caminhos do site são **relativos** (`assets/...`, `politica-de-privacidade.html`),
> então ele funciona tanto em subpasta (`/zoom/`) quanto na raiz de um domínio
> próprio, sem alterar nada.

## Domínio próprio (zmove.net)

O domínio **ainda não está registrado** (sem registros NS/A no DNS). As URLs
absolutas do site já apontam para `https://zmove.net/`, então o único passo que
falta é registrar o domínio e configurar o DNS.

Quando o `zmove.net` estiver registrado:

1. **Registre o domínio** e aponte os servidores de nome do provedor.
2. **No DNS do `zmove.net`**, crie os registros do GitHub Pages:

   | Tipo | Nome | Valor |
   |---|---|---|
   | `A` | `@` | `185.199.108.153` |
   | `A` | `@` | `185.199.109.153` |
   | `A` | `@` | `185.199.110.153` |
   | `A` | `@` | `185.199.111.153` |
   | `AAAA` | `@` | `2606:50c0:8000::153` |
   | `AAAA` | `@` | `2606:50c0:8001::153` |
   | `AAAA` | `@` | `2606:50c0:8002::153` |
   | `AAAA` | `@` | `2606:50c0:8003::153` |

   Se o provedor não aceitar `AAAA`, use apenas os quatro registros `A`.
   Em subdomínios (ex.: `www.zmove.net`) use `CNAME` para
   `zmove-digital.github.io`.
3. **Crie o arquivo `docs/CNAME`** contendo apenas `zmove.net` e faça commit.
   O GitHub Pages passa a servir o site pelo domínio e valida a titularidade
   (pode levar até 24 h para o certificado ser emitido).
4. Em **Settings → Pages**, marque **Enforce HTTPS**.
5. Confira no rodapé do painel do Pages: o status deve ficar
   *Your site is live at https://zmove.net/*.

> Enquanto o `docs/CNAME` não existir, o site continua no endereço padrão
> `https://zmove-digital.github.io/zoom/` — nenhum dos dois quebra o outro.


## Regenerar as artes

As imagens da Google Play e do compartilhamento social ficam em `assets/img/`:

| Arquivo | Tamanho | Uso |
|---|---|---|
| `play-icon-512.png` | 512×512 | Ícone do aplicativo na Play (32 bits, sem transparência) |
| `feature-graphic-1024x500.png` | 1024×500 | Imagem de destaque da listagem na Play |
| `og-zoom.png` | 1200×630 | Imagem de compartilhamento (Open Graph / Twitter Card) |
| `icon-192.png`, `icon-512.png` | 192/512 | Ícones do manifesto do site |
| `tela-*.webp` | 720×1600 | Capturas reais do aplicativo (galeria e mockup do hero) |
| `play-tela-*.png` | 1080×2400 | Mesmas capturas em PNG, para enviar na listagem da Play |

> As capturas são do **build release** rodando com uma base de demonstração
> (usuário fictício "Marina Costa", outubro/2026) — nada de dados reais.
> As imagens em PNG já estão no tamanho exigido pela Play (1080×2400).

## Marca (ZOOM × ZMOVE)

- **ZOOM** é o aplicativo. **ZMOVE** é a empresa que o mantém e publica.
  O cabeçalho mostra `ZOOM` com o selo `da ZMOVE`; o rodapé reforça que o
  ZOOM é um aplicativo da ZMOVE; a seção `#zmove` é o espaço da empresa.
- O símbolo é o **mesmo ícone do aplicativo**: o "Z" verde `#1FF09D` sobre o
  fundo `#080911`. A origem é `assets/branding/logo.png` (e os `mipmap-*` do
  Android) — nada de um logo redesenhado para o site.
- Onde ele aparece:

  | Onde | Arquivo | Observação |
  |---|---|---|
  | Aba do navegador | `favicon.svg` | "Z" vetorial, traçado a partir do logo do app |
  | Manifesto do site | `assets/img/icon-192.png`, `icon-512.png` | tile escuro com o "Z" |
  | Listagem na Play | `assets/img/play-icon-512.png` | 512×512 opaco, igual ao ícone do launcher |
  | Cabeçalho e rodapé | SVG inline em `index.html` e nas páginas legais | não custa requisição extra |

- Se o ícone do aplicativo mudar, `play-icon-512.png`, `icon-192.png`,
  `icon-512.png` e `favicon.svg` precisam ser regerados com o novo logo.


## Ajustes de conteúdo pendentes

Antes de publicar a listagem na Play, revisar:

- **CNPJ** — hoje aparece "CNPJ em processo de regularização" no rodapé,
  na política de privacidade e na página de classificação.
- **E-mail de contato** — `contato@zmove.net` (usar um e-mail real e monitorado).
- **Modelo de cobrança** — o texto do site fala em *teste de 3 dias* e *compra
  única pela Play*. Ajustar se o modelo for alterado.
- **Link da Play** — o botão "Baixar na Google Play" aponta para `#baixar`
  (âncora interna). Trocar pelo endereço da listagem assim que ela existir.
- **Política de reembolso** — a Play exige uma política de reembolso para apps
  com compra; incluir o texto em `politica-de-privacidade.html` ou numa página
  própria.
- **Links do rodapé** — `github.com/zmove-digital/zoom` só deve ser exibido se a
  decisão for publicar o código-fonte.

## Desempenho

O site foi construído para carregar o mais rápido possível:

- **zero requisições externas** (fonte, ícones e scripts são locais);
- CSS único (~15 KB) e JS único (~3 KB), sem frameworks;
- imagens em **WebP**, com `width`/`height` e `loading="lazy"`;
- `font-display: swap` e preload apenas das duas fontes usadas no topo;
- PNG apenas nas artes de compartilhamento/Play, que não são baixadas pelo visitante.
