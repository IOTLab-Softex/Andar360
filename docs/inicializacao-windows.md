# Andar360 no Windows

Use `start_andar360.bat` na raiz do projeto. Ele inicia Rails em producao
na porta 3001 e o worker Delayed Job, com janelas ocultas. Chamadas repetidas
nao duplicam esses processos. O PostgreSQL deve estar disponivel na porta 5432.

Comandos no terminal, a partir da raiz:

```bat
start_andar360.bat start
start_andar360.bat status
start_andar360.bat stop
start_andar360.bat install
start_andar360.bat uninstall
```

`install` cria `Andar360Startup.vbs` na pasta Inicializar do usuario atual.
O sistema inicia ao entrar na conta do Windows, e nao antes do login.
`uninstall` remove somente essa entrada. `stop` encerra somente os processos
do inicializador do Andar360 e preserva o Nginx compartilhado.

## Nginx compartilhado

A instalacao usa `C:\nginx`, a mesma do Aponti TV. O arquivo
`C:\nginx\conf\nginx.conf` inclui `conf.d/andar360.conf` dentro de `http`.
A copia de referencia esta em `config/nginx/andar360.conf` neste repositorio.

- Aponti TV: porta 80, dominio apontitv.com, backend 3000.
- Andar360: porta 80, dominio andar360.ddns.net, backend 3001.
- Andar360 local pelo Nginx: http://localhost:8081.
- Andar360 direto: http://localhost:3001.

O dominio externo depende do DNS e do encaminhamento da porta 80 para esta
maquina. HTTPS nao foi configurado por este inicializador.

Antes de aplicar futuras mudancas:

```bat
C:\nginx\nginx.exe -p C:/nginx/ -t
C:\nginx\nginx.exe -p C:/nginx/ -s reload
```

Os scripts antigos `start_local.bat`, `start_production.bat` e
`start_webrick.ps1` usam a porta 3000; utilize o novo inicializador nesta
maquina para evitar conflito com o Aponti TV.

## Logs e chave local

Logs do servidor e do worker: `log/andar360_*_stdout.log` e
`log/andar360_*_stderr.log`. Erros do inicializador: `log/andar360_startup.log`.

Quando SECRET_KEY_BASE nao esta definida, uma chave persistente e criada em
`storage/andar360_secret_key_base`, ignorada pelo Git. Preserve esse arquivo
entre reinicios para manter a assinatura das sessoes.
