import { type ComponentType, useState } from 'react';
import { NoticeBox, Stack, Tabs } from 'tgui-core/components';

import { useBackend } from '../../backend';
import { Window } from '../../layouts';
import { EmoteTab } from './EmoteTab';
import { ReceivedTab } from './ReceivedTab';
import { StatusTab } from './StatusTab';
import type { HypnosisData, ModuleTabProps } from './types';

/** Tab component for each /datum/hypnosis_module id */
const MODULE_TABS: Record<string, ComponentType<ModuleTabProps<any>>> = {
  emote: EmoteTab,
  received: ReceivedTab,
  status: StatusTab,
};

export const Hypnosis = () => {
  const { act, data } = useBackend<HypnosisData>();
  const { modules, styles } = data;
  const [selectedId, setSelectedId] = useState<string>();
  const selected =
    modules.find((module) => module.id === selectedId) || modules[0];
  const TabComponent = selected && MODULE_TABS[selected.id];

  return (
    <Window width={520} height={560}>
      <Window.Content>
        <Stack vertical fill>
          {modules.length > 1 && (
            <Stack.Item>
              <Tabs>
                {modules.map((module) => (
                  <Tabs.Tab
                    key={module.id}
                    selected={module.id === selected?.id}
                    onClick={() => setSelectedId(module.id)}
                  >
                    {module.name}
                  </Tabs.Tab>
                ))}
              </Tabs>
            </Stack.Item>
          )}
          <Stack.Item grow>
            {!TabComponent ? (
              <NoticeBox>Nothing to show here.</NoticeBox>
            ) : (
              <TabComponent
                module={selected}
                styles={styles}
                moduleAct={(op, params) =>
                  act('module', { module: selected.id, op, ...params })
                }
              />
            )}
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
