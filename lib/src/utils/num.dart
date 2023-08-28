double safeDouble(double input) => input.isNaN || !input.isFinite ? 0 : input.toDouble();
int safeInt(int input) => input.isNaN || !input.isFinite ? 0 : input;
