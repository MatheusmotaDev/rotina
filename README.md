# Rotina

Aplicativo Flutter de planejamento pessoal adaptativo. O projeto usa uma
organização feature-first com MVVM, Riverpod para estado e Supabase como
backend planejado.

## Executar localmente

Sem credenciais, o aplicativo inicia com os dados demonstrativos da tela Hoje:

```sh
flutter run
```

Para conectar um projeto Supabase, copie `.env.example` para `.env` e preencha
a URL e a chave publicável. O arquivo `.env` é local e ignorado pelo Git.

```sh
flutter run
```

No VS Code, use a configuração **Rotina (desenvolvimento)**.

## Validação

```sh
dart analyze
flutter test
```

O Flutter também requer que o Git esteja instalado e disponível no `PATH`.

## Estrutura principal

- `lib/app`: composição do aplicativo.
- `lib/core`: configuração, bootstrap e tema compartilhado.
- `lib/features`: módulos organizados por domínio, apresentação e ViewModel.
- `test`: testes automatizados de interface e navegação.

## Autenticação

O primeiro fluxo integrado usa Supabase Auth para cadastro, confirmação por
e-mail, login, recuperação de senha e encerramento da sessão. Depois da primeira
autenticação, o aplicativo garante a existência do registro correspondente em
`public.perfis` sem sobrescrever configurações de um perfil já existente.
