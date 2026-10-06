from region_state import normalize_regions,active_regions,repair_region
regions=normalize_regions([{'amount':-.15,'mask':'sky.png'},{'amount':.3,'mask':'body.png'}])
assert regions[0]['name']=='Sky' and regions[0]['role']=='background'
assert regions[1]['role']=='depth'
assert repair_region(regions)['mask']=='sky.png'
regions[1]['enabled']=False
assert len(active_regions(regions))==1
assert repair_region(regions)['mask']=='sky.png'
regions[1]['enabled']=True;regions[0]['enabled']=False
try:repair_region(regions)
except ValueError:pass
else:raise AssertionError('Disabled sky accepted')
regions[0]['enabled']=True
regions.append({'amount':-.1,'mask':'other.png','role':'background','enabled':True})
try:repair_region(regions)
except ValueError:pass
else:raise AssertionError('Multiple repair backgrounds accepted')
regions.pop();regions[0]['amount']=.1
try:repair_region(regions)
except ValueError:pass
else:raise AssertionError('Positive repair background accepted')
print('PASS: legacy session migration, separate object edits, toggles, repair-region validation.')
