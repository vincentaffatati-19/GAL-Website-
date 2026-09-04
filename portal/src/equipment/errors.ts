export type EquipmentClientErrorCode = 'AUTH_REQUIRED' | 'GUIDE_RPC_FAILED' | 'AI_FIT_RPC_FAILED';

export class EquipmentClientError extends Error {
  readonly code: EquipmentClientErrorCode;

  constructor(code: EquipmentClientErrorCode, message: string) {
    super(message);
    this.name = 'EquipmentClientError';
    this.code = code;
  }
}
