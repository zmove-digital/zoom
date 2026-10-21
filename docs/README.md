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

## Domínio próprio (zmove.com.br)

Quando o domínio estiver registrado:

1. Crie o arquivo `docs/CNAME` contendo apenas `zmove.com.br`.
2. No DNS, aponte `zmove.com.br` para os IPs do GitHub Pages
   (185.199.108–111.153) **ou** crie um registro `CNAME` para
   `zmove-digital.github.io`.
3. Em **Settings → Pages**, marque **Enforce HTTPS**.
4. Atualize as URLs absolutas em `index.html` (canonical, Open Graph),
   `robots.txt` e `sitemap.xml` — hoje já apontam para `https://zmove.com.br/`.

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


## Ajustes de conteúdo pendentes

Antes de publicar a listagem na Play, revisar:

- **CNPJ** — hoje aparece "CNPJ em processo de regularização" no rodapé,
  na política de privacidade e na página de classificação.
- **E-mail de contato** — `contato@zmove.com.br` (usar um e-mail real e monitorado).
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
