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

type Bet = {
  index: number;
  type: string;
  selection: number;
  amount: number;
};

type Data = {
  linked: BooleanLike;
  casino_name: string;
  phase: string;
  seconds_remaining: number;
  is_dealer: BooleanLike;
  can_deal: BooleanLike;
  dealer_name: string;
  minimum_bet: number;
  final_betting_seconds: number;
  result_number: number | null;
  result_color: string | null;
  my_bets: Bet[];
  board_totals: Record<string, number>;
  held_chip_value: number;
  held_chip_count: number;
};

const redNumbers = new Set([
  1, 3, 5, 7, 9, 12, 14, 16, 18, 19, 21, 23, 25, 27, 30, 32, 34, 36,
]);
const rows = [
  [3, 6, 9, 12, 15, 18, 21, 24, 27, 30, 33, 36],
  [2, 5, 8, 11, 14, 17, 20, 23, 26, 29, 32, 35],
  [1, 4, 7, 10, 13, 16, 19, 22, 25, 28, 31, 34],
];

const cellStyle = (background: string) => ({
  minWidth: 0,
  height: '38px',
  border: '1px solid #e7d7ad',
  background,
  color: '#fff8e7',
  fontWeight: 'bold',
  cursor: 'pointer',
});

export const RouletteTable = () => {
  const { act, data } = useBackend<Data>();
  const [chipCount, setChipCount] = useState(1);
  const [minimumBet, setMinimumBet] = useState(data.minimum_bet);
  const [finalSeconds, setFinalSeconds] = useState(
    data.final_betting_seconds,
  );
  const canBet = data.phase === 'betting' || data.phase === 'final';

  const place = (betType: string, selection = 0) =>
    act('place_bet', {
      bet_type: betType,
      selection,
      chip_count: chipCount,
    });

  return (
    <Window title="Roulette" width={780} height={720} theme="parchment">
      <Window.Content scrollable>
        <div style={pageStyle}>
          <div style={titleStyle}>{data.casino_name}</div>
          <div style={subtitleStyle}>
            {data.dealer_name
              ? `Dealer: ${data.dealer_name}`
              : 'The dealer station is vacant.'}{' '}
            &middot; Minimum wager {data.minimum_bet} units
          </div>
          <hr style={rulerStyle} />

          <div
            style={{
              ...cardStyle,
              minHeight: '106px',
              display: 'grid',
              placeItems: 'center',
              background: '#153e2f',
              color: '#fff8e7',
              textAlign: 'center',
            }}
          >
            {data.phase === 'spinning' ? (
              <div>
                <div style={{ fontSize: '28px' }}>Wheel spinning</div>
                <div>{data.seconds_remaining}s</div>
              </div>
            ) : data.result_number !== null ? (
              <div>
                <div style={{ fontSize: '40px', fontWeight: 'bold' }}>
                  {data.result_number}
                </div>
                <div style={{ textTransform: 'uppercase' }}>
                  {data.result_color}
                </div>
              </div>
            ) : (
              <div style={{ color: '#d8cda9' }}>
                Wheel viewport reserved for ball animation
                {data.phase === 'final' && (
                  <div style={{ color: '#ffd37a', marginTop: '6px' }}>
                    Final betting: {data.seconds_remaining}s
                  </div>
                )}
              </div>
            )}
          </div>

          {!data.linked && (
            <div style={{ ...cardStyle, color: '#8c2f2b', marginTop: '8px' }}>
              This table must be linked at a nearby chip exchange.
            </div>
          )}

          <div style={sectionHeaderStyle}>Betting Cloth</div>
          <div
            style={{
              overflowX: 'auto',
              opacity: canBet ? 1 : 0.64,
              pointerEvents: canBet ? 'auto' : 'none',
            }}
          >
            <div
              style={{
                display: 'grid',
                gridTemplateColumns: '50px repeat(12, 44px) 56px',
                gridTemplateRows: 'repeat(3, 38px)',
                width: '634px',
                margin: '0 auto',
                background: '#0e6b43',
              }}
            >
              <button
                type="button"
                style={{ ...cellStyle('#087542'), gridRow: '1 / span 3' }}
                onClick={() => place('straight', 0)}
              >
                0
              </button>
              {rows.map((row, rowIndex) => (
                <div key={row[0]} style={{ display: 'contents' }}>
                  {row.map((number) => {
                    const total = data.board_totals[`straight-${number}`] || 0;
                    return (
                      <button
                        key={number}
                        type="button"
                        title={total ? `${total} units wagered` : undefined}
                        style={cellStyle(
                          redNumbers.has(number) ? '#a52d31' : '#171717',
                        )}
                        onClick={() => place('straight', number)}
                      >
                        {number}
                        {total > 0 && <small> {total}</small>}
                      </button>
                    );
                  })}
                  <button
                    type="button"
                    style={cellStyle('#0e6b43')}
                    onClick={() => place('column', 3 - rowIndex)}
                  >
                    2:1
                  </button>
                </div>
              ))}
            </div>
            <div
              style={{
                display: 'grid',
                gridTemplateColumns: 'repeat(3, 1fr)',
                width: '528px',
                margin: '0 auto',
              }}
            >
              {[1, 2, 3].map((dozen) => (
                <button
                  key={dozen}
                  type="button"
                  style={cellStyle('#0e6b43')}
                  onClick={() => place('dozen', dozen)}
                >
                  {dozen === 1 ? '1st 12' : dozen === 2 ? '2nd 12' : '3rd 12'}
                </button>
              ))}
            </div>
            <div
              style={{
                display: 'grid',
                gridTemplateColumns: 'repeat(6, 1fr)',
                width: '634px',
                margin: '0 auto',
              }}
            >
              {[
                ['low', '1 to 18'],
                ['even', 'Even'],
                ['red', 'Red'],
                ['black', 'Black'],
                ['odd', 'Odd'],
                ['high', '19 to 36'],
              ].map(([type, label]) => (
                <button
                  key={type}
                  type="button"
                  style={cellStyle(
                    type === 'red'
                      ? '#a52d31'
                      : type === 'black'
                        ? '#171717'
                        : '#0e6b43',
                  )}
                  onClick={() => place(type)}
                >
                  {label}
                </button>
              ))}
            </div>
          </div>

          <div style={sectionHeaderStyle}>Your Chips</div>
          <div
            style={{
              ...cardStyle,
              display: 'flex',
              alignItems: 'center',
              flexWrap: 'wrap',
              gap: '8px',
            }}
          >
            <span style={{ color: INK }}>
              Active hand: {data.held_chip_count} &times;{' '}
              {data.held_chip_value}-unit chips
            </span>
            <NumberInput
              value={chipCount}
              minValue={1}
              maxValue={Math.max(1, data.held_chip_count)}
              step={1}
              width="65px"
              onChange={(value: number) => setChipCount(value)}
            />
            {data.my_bets.map((bet) => (
              <button
                key={bet.index}
                type="button"
                style={inkButtonStyle({ disabled: !canBet })}
                disabled={!canBet}
                onClick={() => act('remove_bet', { index: bet.index })}
              >
                Remove {bet.amount} on {bet.type}
                {bet.type === 'straight' || bet.type === 'dozen' ||
                bet.type === 'column'
                  ? ` ${bet.selection}`
                  : ''}
              </button>
            ))}
          </div>

          {!!data.can_deal && !data.dealer_name && (
            <button
              type="button"
              style={{ ...inkButtonStyle(), marginTop: '10px' }}
              onClick={() => act('claim_dealer')}
            >
              Take Dealer Station
            </button>
          )}

          {!!data.is_dealer && (
            <>
              <div style={sectionHeaderStyle}>Dealer Controls</div>
              <div
                style={{
                  ...cardStyle,
                  display: 'flex',
                  alignItems: 'center',
                  flexWrap: 'wrap',
                  gap: '8px',
                }}
              >
                <span style={{ color: INK_SOFT }}>Minimum</span>
                <NumberInput
                  value={minimumBet}
                  minValue={1}
                  maxValue={1000}
                  step={1}
                  width="65px"
                  onChange={(value: number) => setMinimumBet(value)}
                />
                <span style={{ color: INK_SOFT }}>Final seconds</span>
                <NumberInput
                  value={finalSeconds}
                  minValue={1}
                  maxValue={30}
                  step={1}
                  width="65px"
                  onChange={(value: number) => setFinalSeconds(value)}
                />
                <button
                  type="button"
                  style={inkButtonStyle()}
                  onClick={() =>
                    act('set_rules', {
                      minimum_bet: minimumBet,
                      final_seconds: finalSeconds,
                    })
                  }
                >
                  Set Rules
                </button>
                {data.phase === 'betting' && (
                  <button
                    type="button"
                    style={inkButtonStyle()}
                    onClick={() => act('close_bets')}
                  >
                    Final Betting
                  </button>
                )}
                {data.phase === 'ready' && (
                  <button
                    type="button"
                    style={inkButtonStyle()}
                    onClick={() => act('spin')}
                  >
                    Spin
                  </button>
                )}
                {data.phase === 'result' && (
                  <button
                    type="button"
                    style={inkButtonStyle()}
                    onClick={() => act('next_round')}
                  >
                    Open Next Round
                  </button>
                )}
                <button
                  type="button"
                  style={inkButtonStyle()}
                  onClick={() => act('end_game')}
                >
                  Leave Dealer Station
                </button>
              </div>
            </>
          )}

          <div style={{ color: SEAL_AMBER, marginTop: '8px' }}>
            Phase: {data.phase}
          </div>
        </div>
      </Window.Content>
    </Window>
  );
};
