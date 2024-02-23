import os
import requests

def get_nightly_release(headers, releases_url):
    """Get the 'nightly' release if it exists."""
    response = requests.get(releases_url, headers=headers)
    response.raise_for_status()  # Ensure we raise an exception for bad responses
    releases = response.json()
    for release in releases:
        if release['name'] == 'nightly':
            return release
    return None

def delete_release_assets(headers, release):
    """Delete all assets associated with a release."""
    assets = release['assets']
    for asset in assets:
        asset_url = asset['url']
        response = requests.delete(asset_url, headers=headers)
        response.raise_for_status()

def create_or_update_nightly_release(headers, releases_url, existing_release=None):
    """Create or update the 'nightly' release."""
    data = {
        'tag_name': 'nightly',
        'name': 'nightly',
        'body': 'Nightly build',
        'draft': False,
        'prerelease': True,
    }
    if existing_release:
        # Update existing release
        update_url = existing_release['url']
        response = requests.post(update_url, headers=headers, json=data)
    else:
        # Create new release
        response = requests.post(releases_url, headers=headers, json=data)
    response.raise_for_status()
    return response.json()

def main():
    github_token = os.getenv('GITHUB_TOKEN')
    repo_name = os.getenv('REPO_NAME')
    headers = {
        'Authorization': f'token {github_token}',
        'Accept': 'application/vnd.github.v3+json',
    }
    releases_url = f'https://api.github.com/repos/{repo_name}/releases'

    # Check for an existing "nightly" release
    nightly_release = get_nightly_release(headers, releases_url)

    # If it exists, delete its assets
    if nightly_release:
        delete_release_assets(headers, nightly_release)

    # Create or update the "nightly" release
    release = create_or_update_nightly_release(headers, releases_url, existing_release=nightly_release)
    
    # Print the upload URL for the GitHub Actions step to use
    print(release['upload_url'].split('{')[0])  # Removes the URL template part

if __name__ == '__main__':
    main()
