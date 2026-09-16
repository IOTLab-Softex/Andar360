# Acesso do Aponti TV pelo Andar360

Em Empresas > Editar > Subgrupos, edite o setor e marque **Acessar Aponti TV**.
A permissao inicia desmarcada e pode ser alterada por administrador ou operador.
O participante deve pertencer a mesma empresa do subgrupo autorizado, ter usuario
no Andar360 e nao estar bloqueado, excluido ou com solicitacao de exclusao pendente.
Nenhum subgrupo recebe acesso automaticamente durante a migration.

Depois, como administrador, edite o participante desse subgrupo. Em **Acesso ao
sistema**, marque **Conceder acesso ao Aponti TV**. A opcao **Conceder acesso ao
Andar360** e independente: deixe-a desmarcada para acesso somente a TV. A conta
e a senha continuam gerenciadas no cadastro, mas nao permitem entrar no 360.
A opcao da TV so aparece para setores habilitados.
O acesso exige as duas autorizacoes: a do subgrupo e a individual. A autorizacao
individual inicia desmarcada, inclusive para participantes existentes. Ao salvar
um participante em setor desabilitado ou de outra empresa, ela e removida.

O Aponti TV aceita CPF ou e-mail e a senha atual do Andar360. No primeiro login,
vincula a conta local pelo e-mail ou cria uma conta sem privilegios de administrador.
Administradores locais existentes conservam seu papel quando a identidade e vinculada,
mas precisam da mesma permissao do Andar360. O login Google exige e-mail verificado
e autorizacao no Andar360. Senhas locais antigas nao permitem contornar a integracao.

Esqueci minha senha e alteracoes de senha encaminham para `/recuperar-senha` no
Andar360, reutilizando o fluxo de suporte/validacao facial existente. A troca de
senha e a retirada de permissao invalidam as sessoes do Aponti TV na proxima consulta.
Quando `force_password_change` esta ativo (senha gerada pelo administrador), o
Aponti TV exige uma nova senha em `/shared_password/edit` antes de liberar as
outras paginas. A senha e atualizada no Andar360, inclusive para contas somente
TV, e a flag e removida. A senha anterior e os links anteriores de redefinicao
deixam de valer; a sessao atual e renovada. A conta root local nao usa esse fluxo.

A foto do participante e exibida no perfil do Aponti TV por `/profile_photo`.
O servidor busca a imagem no 360 com o token de integracao, sem expor esse token
ao navegador. Somente a foto do usuario autenticado e servida, sem cache publico.
Sem foto disponivel, o perfil usa a inicial do e-mail.
Se o Andar360 estiver indisponivel, o acesso autenticado ao Aponti TV e recusado.

## Configuracao local

O Aponti TV consulta `http://127.0.0.1:3001/integrations/aponti_tv/` por POST.
As acoes `authenticate` e `authorize` exigem um token de servico no cabecalho Bearer.
A API nao devolve a senha nem seu hash; a versao de sessao e um HMAC.

O mesmo token esta em arquivos ignorados pelo Git:

- Andar360: `storage/aponti_tv_integration_token`.
- Aponti TV: `storage/andar360_integration_token`.

Variaveis opcionais: `APONTI_TV_INTEGRATION_TOKEN` no Andar360;
`ANDAR360_INTEGRATION_TOKEN`, `ANDAR360_INTERNAL_URL` e `ANDAR360_PUBLIC_URL`
no Aponti TV. Comunicacao interna fora do loopback exige HTTPS.
No navegador local, a recuperacao usa `http://localhost:8081`;
nos demais hosts, usa `ANDAR360_PUBLIC_URL` ou `http://andar360.ddns.net`.

Migracoes: `20260914140000` no banco principal do Andar360 e `20260914141000`
no Aponti TV. Reinicie os dois servidores apos instalar as alteracoes.

Validacao automatizada: 4 testes no Andar360 (16 assercoes), 8 no Aponti TV
(20 assercoes). Inclui senha incorreta, permissao negada, empresa divergente,
bloqueio, recuperacao, Google, indisponibilidade e invalidacao de sessoes.
