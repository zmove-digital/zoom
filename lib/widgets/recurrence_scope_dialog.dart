import 'package:flutter/material.dart';

enum RecurrenceScope { single, thisAndFuture }

Future<RecurrenceScope?> showEditScopeDialog(BuildContext context) {
  return showDialog<RecurrenceScope>(
    context: context,
    builder: (BuildContext context) => SimpleDialog(
      title: const Text('Editar lançamento repetido'),
      children: <Widget>[
        SimpleDialogOption(
          onPressed: () => Navigator.pop(context, RecurrenceScope.single),
          child: const Text('Editar somente essa'),
        ),
        SimpleDialogOption(
          onPressed: () =>
              Navigator.pop(context, RecurrenceScope.thisAndFuture),
          child: const Text('Editar essa e as futuras'),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    ),
  );
}

Future<RecurrenceScope?> showDeleteScopeDialog(BuildContext context) {
  return showDialog<RecurrenceScope>(
    context: context,
    builder: (BuildContext context) => SimpleDialog(
      title: const Text('Excluir lançamento repetido'),
      children: <Widget>[
        SimpleDialogOption(
          onPressed: () => Navigator.pop(context, RecurrenceScope.single),
          child: const Text('Excluir somente essa'),
        ),
        SimpleDialogOption(
          onPressed: () =>
              Navigator.pop(context, RecurrenceScope.thisAndFuture),
          child: const Text('Excluir essa e todas as futuras'),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    ),
  );
}
