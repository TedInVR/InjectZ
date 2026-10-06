def normalize_regions(regions):
    """Add names/roles to older session snapshots without discarding edits."""
    for i,region in enumerate(regions):
        region.setdefault('name','Sky' if i==0 and region['amount']<0 else 'Change '+str(i+1))
        region.setdefault('role','background' if i==0 and region['amount']<0 else 'depth')
        region.setdefault('enabled',True)
    return regions

def active_regions(regions):
    return [region for region in regions if region.get('enabled',True)]

def repair_region(regions):
    sky=[region for region in active_regions(regions) if region.get('role')=='background']
    if len(sky)!=1 or sky[0]['amount']>=0:
        raise ValueError('Repair needs exactly one enabled Sky/background edit with a negative adjustment. Other enabled edits may adjust foreground depth.')
    return sky[0]


def merge_masks(paths, mode, output):
    from PIL import Image,ImageChops
    if mode not in ('latest','union'):raise ValueError('Unknown merge method.')
    with Image.open(paths[-1]) as im:merged=im.convert('L').copy()
    if mode=='union':
        for path in paths[:-1]:
            with Image.open(path) as im:
                if im.size!=merged.size:raise ValueError('Saved selection sizes differ.')
                merged=ImageChops.lighter(merged,im.convert('L'))
    merged.save(output)
