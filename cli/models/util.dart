// Prisma serializa campos Decimal como string; aceita string ou num.
double parseNum(dynamic valor) {
  if (valor is num) return valor.toDouble();
  return double.parse(valor.toString());
}
