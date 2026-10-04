import json,pathlib,sys
from iw3.utils import create_parser
rows=json.loads(pathlib.Path(sys.argv[1]).read_text())
parser=create_parser(required_true=False)
by_flag={flag:a for a in parser._actions for flag in a.option_strings}
for row in rows:
    action=by_flag.get(row['flag'])
    if action is None: raise SystemExit('Installed option missing: '+row['flag'])
    value=action.default
    # This is an Inject Z override, rather than the standalone parser's None.
    if row['flag']=='--inpaint-model': value='light_inpaint_v1'
    if isinstance(value,bool): label='On' if value else 'Off'
    elif value is None:
        label={'--autocrop':'Off','--pad':'0 (no padding)','--metadata':'Off','--max-output-width':'No limit','--max-output-height':'No limit'}.get(row['flag'],'Automatic')
    elif isinstance(value,(tuple,list)): label=' '.join(map(str,value))
    else: label=str(value)
    row['defaultLabel']=label
pathlib.Path(sys.argv[2]).write_text(json.dumps(rows,indent=2))
print('Resolved actual defaults for',len(rows),'settings.')
