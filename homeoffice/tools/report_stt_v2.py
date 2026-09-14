from pathlib import Path
import json,re,unicodedata,statistics
R=Path(__file__).resolve().parents[1];d=json.loads((R/'evidence/v2-stt-browser.json').read_text(encoding='utf8'))
def distance(a,b):
 row=list(range(len(b)+1))
 for i,x in enumerate(a,1):
  nextrow=[i]
  for j,y in enumerate(b,1):nextrow.append(min(nextrow[-1]+1,row[j]+1,row[j-1]+(x!=y)))
  row=nextrow
 return row[-1]
def normalize(s):return re.sub(r'[^\w\s]','',unicodedata.normalize('NFC',s)).strip()
rows=[];chars=words=charerr=worderr=0
for r in d.get('results',[]):
 expected=normalize(r['reference']);actual=normalize(r['result']['text']);a=expected.replace(' ','');b=actual.replace(' ','');ce=distance(a,b);we=distance(expected.split(),actual.split());chars+=len(a);words+=len(expected.split());charerr+=ce;worderr+=we
 rows.append({'id':r['id'],'reference':r['reference'],'recognized':r['result']['text'],'cer':ce/len(a),'wer':we/len(expected.split()),'inferenceMs':r['result']['elapsedMs'],'gameFPS':r['performance'].get('fps')})
out={'source':'Microsoft Heami Desktop synthetic speech; not human microphone','normalization':'NFC, punctuation removed, CER excludes spaces, WER uses whitespace tokens. Numbers/meaning not rewritten.','utterances':len(rows),'cer':charerr/chars if chars else None,'wer':worderr/words if words else None,'modelBytes':d.get('download',{}).get('progress_total',{}).get('loaded'),'baseline':d.get('baseline'),'results':rows,'memory':'Godot web MEMORY_STATIC returned 0 (unavailable); JS heap is not WASM/GPU/process memory. Total model/runtime memory not yet measured.'}
(R/'evidence/v2-stt-metrics.json').write_text(json.dumps(out,ensure_ascii=False,indent=2),encoding='utf8')
lines=['# 한국어 자막 실제 측정','', '**합성 음성 시험이며 실제 사람/마이크 품질 검증을 대신하지 않는다.**','',f"Whisper tiny q8 / Transformers.js 4.2.0 / ONNX WASM 1 thread, graph optimization disabled. 모델·설정·토크나이저 {out['modelBytes']:,} bytes. 한국어 6문장, Microsoft Heami Desktop, 1920×1080 Godot 동시 실행.",'',f"이 작은 합성 집합의 CER {out['cer']:.1%}, WER {out['wer']:.1%}. 이름·날짜·숫자 오류가 있어 품질 완료로 판정하지 않는다. 인식 후 LLM이나 규칙으로 의미를 추정하여 고치지 않았다.",'', 'CER: NFC/구두점 제거/공백 제외. WER: 같은 정규화 후 공백 단위. 숫자 표기는 강제 변환하지 않았다. 입력 구간 4.18–5.30초, 추론 1.35–1.69초. 실제 마이크의 발화 종료→최종 자막 지연과는 별도다.','', '| 원문 | 실제 인식 | 추론 ms | 게임 FPS 표본 |','|---|---|---:|---:|']
for r in rows:lines.append(f"| {r['reference']} | {r['recognized']} | {r['inferenceMs']:.0f} | {r['gameFPS']} |")
lines+=['','브라우저 SpeechRecognition의 API 존재를 확인했지만, headless 언어팩 available 조회에서 탭이 종료됐다. 자동 headless에서는 해당 조회를 제한하고 제약을 표시한다. 실제 데스크톱 Chrome/Edge의 ko-KR 언어팩·외부 처리 경로와 여러 사람/마이크 시험은 **필수 미완료**다.','', 'Whisper 모델 다운로드는 선택 사항이고 Hugging Face에서 가중치만 받는다. 음성은 로컬 AudioWorklet→WASM worker에서 처리하며 기본 원음/전사 저장은 없다. 브라우저 외부 인식 모드는 별도 동의가 필요하고 자동 전환하지 않는다.','', '초기 ONNX 런타임 누락 및 양자화 최적화 오류를 실제로 수정한 구성이다. 최적화 전 1080p FPS 표본은 32–38이었다. 조명 최적화 후 수치는 별도 성능 보고서를 따른다.','', '메모리: web Godot static memory=0은 미지원/미계측으로 처리한다. JS heap은 WASM/GPU/프로세스 전체 메모리가 아니다. 전체 메모리 및 실제 사람의 CER/WER/지연 측정은 남아 있다.']
(R/'docs/v2/korean-stt-measurement.md').write_text('\n'.join(lines)+'\n',encoding='utf8')
print(json.dumps({k:out[k] for k in ['utterances','cer','wer','modelBytes']},ensure_ascii=False))
