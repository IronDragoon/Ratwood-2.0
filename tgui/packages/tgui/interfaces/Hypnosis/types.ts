export type HypnosisStyle = {
  id: string;
  name: string;
  desc: string;
  css_class: string;
};

export type HypnosisModule<T = unknown> = {
  id: string;
  name: string;
  desc: string;
  data: T;
};

export type HypnosisData = {
  styles: HypnosisStyle[];
  modules: HypnosisModule[];
};

export type ModuleTabProps<T> = {
  module: HypnosisModule<T>;
  styles: HypnosisStyle[];
  /** Sends an op to this module's execute() */
  moduleAct: (op: string, params?: Record<string, unknown>) => void;
};
