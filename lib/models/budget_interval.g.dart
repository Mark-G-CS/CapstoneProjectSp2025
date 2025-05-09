// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget_interval.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BudgetIntervalAdapter extends TypeAdapter<BudgetInterval> {
  @override
  final int typeId = 1;

  @override
  BudgetInterval read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BudgetInterval.weekly;
      case 1:
        return BudgetInterval.monthly;
      default:
        return BudgetInterval.weekly;
    }
  }

  @override
  void write(BinaryWriter writer, BudgetInterval obj) {
    switch (obj) {
      case BudgetInterval.weekly:
        writer.writeByte(0);
        break;
      case BudgetInterval.monthly:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetIntervalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
