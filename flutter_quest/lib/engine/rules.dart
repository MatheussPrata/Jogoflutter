// Motor de validação: regras declarativas sobre a árvore de widgets.
//
// Uma fase declara o que espera; o motor diz se o código do aluno cumpre.
// A validação é estrutural — `Text('oi')` e `Text("oi")` são equivalentes.

import 'parser.dart';

/// Uma regra que a árvore de widgets precisa satisfazer.
sealed class Rule {
  const Rule();
}

/// Exige que exista um widget com este nome.
class HasWidget extends Rule {
  final String name;
  const HasWidget(this.name);
}

/// Exige que [parent] tenha um filho direto [child].
class HasChild extends Rule {
  final String parent;
  final String child;
  const HasChild({required this.parent, required this.child});
}

/// Exige que um widget tenha certa propriedade com certo valor textual.
class HasProperty extends Rule {
  final String widget;
  final String property;
  final String? equals;
  const HasProperty(this.widget, this.property, {this.equals});
}

/// Exige um número mínimo de filhos diretos.
class MinChildren extends Rule {
  final String widget;
  final int count;
  const MinChildren(this.widget, this.count);
}

/// Exige que um widget seja o mais externo da árvore.
class IsRoot extends Rule {
  final String widget;
  const IsRoot(this.widget);
}

/// Exige que um `Text` contenha exatamente este texto.
class HasText extends Rule {
  final String text;
  const HasText(this.text);
}

/// Exige que exista uma propriedade em qualquer nó, com valor numérico >= [atLeast].
class PropertyAtLeast extends Rule {
  final String widget;
  final String property;
  final double atLeast;
  const PropertyAtLeast(this.widget, this.property, this.atLeast);
}

/// Resultado da validação de uma fase.
class RuleResult {
  final bool ok;
  final List<String> failures;

  const RuleResult(this.ok, this.failures);

  static RuleResult pass() => const RuleResult(true, []);
  static RuleResult fail(List<String> failures) => RuleResult(false, failures);
}

/// Valida a árvore contra uma lista de regras.
RuleResult validate(Node tree, List<Rule> rules) {
  final failures = <String>[];

  for (final rule in rules) {
    final message = _check(tree, rule);
    if (message != null) failures.add(message);
  }

  return failures.isEmpty ? RuleResult.pass() : RuleResult.fail(failures);
}

String? _check(Node tree, Rule rule) {
  final all = flatten(tree);

  switch (rule) {
    case HasWidget(:final name):
      if (!all.any((n) => n.name == name)) {
        return 'Falta um widget $name.';
      }
      return null;

    case HasChild(:final parent, :final child):
      final parents = all.where((n) => n.name == parent);
      if (parents.isEmpty) return 'Falta um widget $parent.';
      if (!parents.any((p) => p.children.any((c) => c.name == child))) {
        return 'O $parent precisa ter um $child dentro dele.';
      }
      return null;

    case HasProperty(:final widget, :final property, :final equals):
      final matches = all.where((n) => n.name == widget);
      if (matches.isEmpty) return 'Falta um widget $widget.';
      final withProp = matches.where((n) => n.args.containsKey(property));
      if (withProp.isEmpty) {
        return 'O $widget precisa da propriedade "$property".';
      }
      if (equals != null && !withProp.any((n) => n.args[property]!.texto == equals)) {
        return 'A propriedade "$property" do $widget deveria ser "$equals".';
      }
      return null;

    case MinChildren(:final widget, :final count):
      final matches = all.where((n) => n.name == widget && n.children.length >= count);
      if (!matches.any((n) => n.name == widget)) {
        return 'Falta um widget $widget.';
      }
      if (matches.isEmpty) {
        return 'O $widget precisa ter pelo menos $count filhos.';
      }
      return null;

    case IsRoot(:final widget):
      if (tree.name != widget) {
        return 'O widget mais externo deveria ser $widget.';
      }
      return null;

    case HasText(:final text):
      final texts = all.where((n) => n.name == 'Text' && n.text == text);
      if (texts.isEmpty) {
        return 'Nenhum Text mostra "$text".';
      }
      return null;

    case PropertyAtLeast(:final widget, :final property, :final atLeast):
      final matches = all.where((n) => n.name == widget);
      if (matches.isEmpty) return 'Falta um widget $widget.';
      final values = matches
          .map((n) => double.tryParse(n.args[property]?.texto ?? ''))
          .whereType<double>();
      if (values.isEmpty) {
        return 'O $widget precisa de "$property" com um número.';
      }
      if (!values.any((v) => v >= atLeast)) {
        return '"$property" do $widget deveria ser pelo menos $atLeast.';
      }
      return null;
  }
}

/// Todos os nós da árvore, em profundidade.
List<Node> flatten(Node root) {
  final out = <Node>[];
  void walk(Node n) {
    out.add(n);
    for (final c in n.children) {
      walk(c);
    }
  }

  walk(root);
  return out;
}
