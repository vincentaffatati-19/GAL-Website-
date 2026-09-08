from pathlib import Path
from playwright.sync_api import sync_playwright

RC = Path('/mnt/data/gal-step17/GAL-UX10.02-STEP17.3.2-DYNAMIC-VISUAL-RC.html').resolve()
GENDERS = ['', 'Male', 'Female', 'Non-binary / another identity', 'Prefer not to say']
AGES = ['', 'Under 18', '18–24', '25–34', '35–44', '45–54', '55–64', '65–74', '75+', 'Prefer not to say']


def expected_family(gender, age):
    if age == 'Under 18':
        if gender == 'Male': return 'male'
        if gender == 'Female': return 'female'
        return 'neutral'
    if gender == 'Male': return 'male'
    if gender == 'Female': return 'female'
    return 'neutral'


def family_from_key(key):
    if key.startswith('male_') or key == 'junior_male': return 'male'
    if key.startswith('female_') or key == 'junior_female': return 'female'
    if key.startswith('neutral_'): return 'neutral'
    return 'unknown'


def intersects(a, b):
    return not (a['x'] + a['width'] <= b['x'] or b['x'] + b['width'] <= a['x'] or
                a['y'] + a['height'] <= b['y'] or b['y'] + b['height'] <= a['y'])

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True, executable_path='/usr/bin/chromium', args=['--no-sandbox'])
    errors = []

    page = browser.new_page(viewport={'width': 1440, 'height': 1000})
    page.on('pageerror', lambda exc: errors.append(str(exc)))
    page.set_content(RC.read_text(encoding='utf-8'), wait_until='domcontentloaded')
    page.wait_for_function('window.GALProfileReview !== undefined')
    mismatches = []
    for gender in GENDERS:
        for age in AGES:
            key = page.evaluate('([g,a]) => window.GALProfileReview.resolveGolferVisual(g,a)', [gender, age])
            actual = family_from_key(key)
            expected = expected_family(gender, age)
            if actual != expected:
                mismatches.append((gender or 'Not provided', age or 'Not provided', key, expected, actual))
    assert not mismatches, 'Gender/age resolver mismatches: ' + repr(mismatches)

    assert page.evaluate("window.GALProfileReview.resolveGolferVisual('Female','')").startswith('female_')
    assert page.evaluate("window.GALProfileReview.resolveGolferVisual('Female','Prefer not to say')").startswith('female_')
    assert page.evaluate("window.GALProfileReview.resolveGolferVisual('Male','')").startswith('male_')
    assert page.evaluate("window.GALProfileReview.resolveGolferVisual('Male','Prefer not to say')").startswith('male_')

    for gender, age in [('Female',''), ('Female','Prefer not to say'), ('Male',''), ('Male','Prefer not to say')]:
        page.select_option('#genderField', gender)
        page.select_option('#ageField', age)
        page.wait_for_timeout(50)
        src = page.locator('#dynamicMeasurementVisual').get_attribute('src') or ''
        assert src.startswith('data:image/'), (gender, age, src[:80])
        assert page.evaluate("document.getElementById('dynamicMeasurementVisual').naturalWidth") > 0

    for toggle_id, content_id in [('profileReviewToggle', 'profileReviewContent'), ('auditToggle', 'auditContent')]:
        toggle = page.locator(f'#{toggle_id}')
        content = page.locator(f'#{content_id}')
        assert toggle.get_attribute('aria-expanded') == 'false'
        assert content.is_hidden()
        assert toggle.inner_text().strip() == '+'
        toggle.click()
        assert toggle.get_attribute('aria-expanded') == 'true'
        assert content.is_visible()
        assert toggle.inner_text().strip() == '−'
        toggle.click()
        assert content.is_hidden()

    miss_visual = page.locator('#area-miss .miss-reference')
    miss_img = page.locator('#area-miss .miss-reference img')
    assert miss_visual.count() == 1
    assert page.evaluate("getComputedStyle(document.querySelector('#area-miss .miss-reference img')).objectFit") == 'contain'
    img_box = miss_img.bounding_box()
    save_box = page.locator('#saveMiss').bounding_box()
    assert img_box and save_box and not intersects(img_box, save_box)
    natural = page.evaluate("() => { const i=document.querySelector('#area-miss .miss-reference img'); return [i.naturalWidth,i.naturalHeight]; }")
    rendered_ratio = img_box['width'] / img_box['height']
    natural_ratio = natural[0] / natural[1]
    assert abs(rendered_ratio - natural_ratio) < 0.03
    page.close()

    mobile = browser.new_page(viewport={'width': 390, 'height': 844})
    mobile.on('pageerror', lambda exc: errors.append(str(exc)))
    mobile.set_content(RC.read_text(encoding='utf-8'), wait_until='domcontentloaded')
    miss_img = mobile.locator('#area-miss .miss-reference img')
    img_box = miss_img.bounding_box()
    save_box = mobile.locator('#saveMiss').bounding_box()
    assert img_box and save_box and not intersects(img_box, save_box)
    natural = mobile.evaluate("() => { const i=document.querySelector('#area-miss .miss-reference img'); return [i.naturalWidth,i.naturalHeight]; }")
    rendered_ratio = img_box['width'] / img_box['height']
    natural_ratio = natural[0] / natural[1]
    assert abs(rendered_ratio - natural_ratio) < 0.03
    mobile.close()

    assert not errors, 'Page errors: ' + repr(errors)
    browser.close()

print('PASS')
