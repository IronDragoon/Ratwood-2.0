import { useState } from 'react';
import { NumberInput } from 'tgui-core/components';
import type { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';
import {
  cardStyle,
  INK,
  INK_SOFT,
  inkButtonStyle,
  pageStyle,
  rulerStyle,
  SEAL_AMBER,
  sectionHeaderStyle,
  subtitleStyle,
  titleStyle,
} from './common/parchment';

type Data = {
  claimed: BooleanLike;
  is_owner: BooleanLike;
  casino_name: string;
  exchange_rate: number;
  reserve: number;
  liability: number;
  equity: number;
  outstanding_units: number;
  pending_credit: number;
  nearby_people: Array<{
    ref: string;
    name: string;
    authorized: BooleanLike;
  }>;
  nearby_tables: Array<{ ref: string; name: string; linked: BooleanLike }>;
};

const denominations = [1, 5, 10, 25, 100];

export const ChipExchange = () => {
  const { act, data } = useBackend<Data>();
  const [count, setCount] = useState(1);
  const [rate, setRate] = useState(data.exchange_rate);

  return (
    <Window title="Chip Exchange" width={540} height={560} theme="parchment">
      <Window.Content scrollable>
        <div style={pageStyle}>
          <div style={titleStyle}>{data.casino_name}</div>
          <div style={subtitleStyle}>
            One chip unit redeems for{' '}
            <b style={{ color: SEAL_AMBER }}>{data.exchange_rate}m</b>
          </div>
          <hr style={rulerStyle} />

          {!data.claimed ? (
            <button
              type="button"
              style={inkButtonStyle()}
              onClick={() => act('claim')}
            >
              Claim Cashier
            </button>
          ) : (
            <>
              <div style={sectionHeaderStyle}>Exchange</div>
              <div style={cardStyle}>
                <div style={{ color: INK, marginBottom: '8px' }}>
                  Deposited credit: <b>{data.pending_credit}m</b>
                </div>
                <div
                  style={{ display: 'flex', alignItems: 'center', gap: '8px' }}
                >
                  <span style={{ color: INK_SOFT }}>Stacks:</span>
                  <NumberInput
                    value={count}
                    minValue={1}
                    maxValue={20}
                    step={1}
                    width="60px"
                    onChange={(value: number) => setCount(value)}
                  />
                  <button
                    type="button"
                    style={inkButtonStyle({ disabled: !data.pending_credit })}
                    disabled={!data.pending_credit}
                    onClick={() => act('refund')}
                  >
                    Return Deposit
                  </button>
                </div>
                <div
                  style={{
                    display: 'grid',
                    gridTemplateColumns: 'repeat(5, minmax(0, 1fr))',
                    gap: '6px',
                    marginTop: '12px',
                  }}
                >
                  {denominations.map((denomination) => {
                    const cost = denomination * count * data.exchange_rate;
                    return (
                      <button
                        key={denomination}
                        type="button"
                        style={inkButtonStyle({
                          disabled: data.pending_credit < cost,
                        })}
                        disabled={data.pending_credit < cost}
                        onClick={() =>
                          act('buy', { denomination, count })
                        }
                      >
                        {denomination}
                        <br />
                        <small>{cost}m</small>
                      </button>
                    );
                  })}
                </div>
              </div>

              <div style={sectionHeaderStyle}>House Ledger</div>
              <div style={cardStyle}>
                Reserve {data.reserve}m &middot; Claims {data.liability}m
                <br />
                Outstanding {data.outstanding_units} units &middot; Equity{' '}
                {data.equity}m
              </div>

              {!!data.is_owner && (
                <>
                  <div style={sectionHeaderStyle}>Owner Seal</div>
                  <div
                    style={{
                      ...cardStyle,
                      display: 'flex',
                      alignItems: 'center',
                      gap: '8px',
                    }}
                  >
                    <span style={{ color: INK_SOFT }}>Mammon per unit</span>
                    <NumberInput
                      value={rate}
                      minValue={1}
                      maxValue={100}
                      step={1}
                      width="70px"
                      onChange={(value: number) => setRate(value)}
                    />
                    <button
                      type="button"
                      style={inkButtonStyle({
                        disabled:
                          !!data.reserve || !!data.outstanding_units,
                      })}
                      disabled={!!data.reserve || !!data.outstanding_units}
                      onClick={() => act('set_rate', { rate })}
                    >
                      Set Rate
                    </button>
                  </div>
                  <div
                    style={{
                      ...cardStyle,
                      display: 'flex',
                      gap: '8px',
                      marginTop: '8px',
                    }}
                  >
                    <button
                      type="button"
                      style={inkButtonStyle({ disabled: !data.pending_credit })}
                      disabled={!data.pending_credit}
                      onClick={() => act('fund_house')}
                    >
                      Add Deposit to House Reserve
                    </button>
                    <button
                      type="button"
                      style={inkButtonStyle({ disabled: !data.equity })}
                      disabled={!data.equity}
                      onClick={() =>
                        act('withdraw_equity', { amount: data.equity })
                      }
                    >
                      Withdraw {data.equity}m Equity
                    </button>
                  </div>

                  <div style={sectionHeaderStyle}>Nearby Dealers</div>
                  <div style={cardStyle}>
                    {data.nearby_people.length ? (
                      data.nearby_people.map((person) => (
                        <button
                          key={person.ref}
                          type="button"
                          style={{ ...inkButtonStyle(), margin: '3px' }}
                          onClick={() =>
                            act('authorize_dealer', { ref: person.ref })
                          }
                        >
                          {person.authorized ? 'Revoke' : 'Authorize'}{' '}
                          {person.name}
                        </button>
                      ))
                    ) : (
                      <span style={{ color: INK_SOFT }}>No one nearby.</span>
                    )}
                  </div>

                  <div style={sectionHeaderStyle}>Nearby Tables</div>
                  <div style={cardStyle}>
                    {data.nearby_tables.length ? (
                      data.nearby_tables.map((table) => (
                        <button
                          key={table.ref}
                          type="button"
                          style={{ ...inkButtonStyle(), margin: '3px' }}
                          disabled={!!table.linked}
                          onClick={() => act('link_table', { ref: table.ref })}
                        >
                          {table.linked ? 'Linked' : 'Link'} {table.name}
                        </button>
                      ))
                    ) : (
                      <span style={{ color: INK_SOFT }}>No table nearby.</span>
                    )}
                  </div>
                </>
              )}
            </>
          )}
        </div>
      </Window.Content>
    </Window>
  );
};
