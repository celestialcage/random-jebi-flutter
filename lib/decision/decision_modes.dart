import 'package:random_jebi_flutter/decision/decision_models.dart';

const List<DecisionMode> decisionModes = [
  DecisionMode(id: 'do', label: '할까?', positive: '해', negative: '하지마'),
  DecisionMode(id: 'buy', label: '살까?', positive: '사', negative: '사지마'),
  DecisionMode(id: 'go', label: '갈까?', positive: '가', negative: '가지마'),
  DecisionMode(id: 'eat', label: '먹을까?', positive: '먹어', negative: '먹지마'),
  DecisionMode(id: 'drink', label: '마실까?', positive: '마셔', negative: '마시지마'),
];
