# gen-hotupdate-for-cocos-lua

Will auto-generate hotupdates at server-side for working together with `AssetsManagerEx` of Cocos-lua.

This is still a very rough implementation and welcome for improvements and suggestions.

Contact Me:

QQ:176121421

Email:jerome.hellomeow@gmail.com

## Dependencies

* [GitPython](http://t.cn/RUTulbV?u=1676472840&m=3909405524993036&cu=1676472840)

## `gen_hotupdate.py`

Will do the following:

* update the project using git pull [may ask for username/password]
* get the changed file list from `c_base_commit` to `c_head_commit` [status marked as 'A', 'R' or 'M']
* generate md5 for each file
* generate new version based on current version stored in `c_version_manifest_name`
* clear `c_project_dir` and `c_version_dir` contents
* copy all files in the list to `c_project_dir` with their directory structure unchanged.
* generate `c_project_manifest_name` and `c_version_manifest_name` and save them to `c_project_manifest_name` and `c_project_manifest_name`

## `cfg_hotupdate.txt`

Contains json formatted configurations for `gen_hotupdate.py` to parse and use.

Keys:

Key|Meaning
:---|:---
`c_repo_dir`|your cocos-lua project root directory, MUST git initialized
`c_base_commit`|SHA-1 value of a commit you choose for checking file changes compared with `c_head_commit`
`c_head_commit`|usually set as `HEAD`
`c_project_dir`|root directory for storing files changed since `c_base_commit` and `project.manifest`
`c_version_dir`|root directory for storing `version.manifest`
`c_project_manifest_name`|must be the same value as client settings, by default is `project.manifest`
`c_version_manifest_name`|must be the same value as client settings, by default is `version.manifest`
`c_dir_0`|directory watch list, any file change in the directory included in the list will be recorded and updated
`c_package_url` | url where the updated files can  be downloaded
`c_manifest_url` | url where the `project.manifest` can be downloaded
`c_version_url`| url where the `version.manifest` can be downloaded
`c_major_version` | major version for project


NOTE:

* version format is "major.date.minor":
	* `major` is the project version set by you.
	* `date` is the date when this script is running
	* `minor`'s default value is 1 for a new day or for the first time the script is runned, and will increase by 1 each time the script is runned for the same day.

* project.manifest example

```
{
    "packageUrl": "http://host:8080/update/files/",
    "remoteVersionUrl": "http://host:8080/update/version/version.manifest",
    "version": "1.20151115.1",
    "engineVersion": "Quick 3.5",
    "remoteManifestUrl": "http://host:8080/update/version/project.manifest",
    "searchPaths": [],
    "assets": {
        "src/app/views/TestScene.lua": {
            "md5": "73553860c47baff122621afbfdec1c60"
        },
        "src/main.lua": {
            "md5": "5c6297d13e672edc7dd3187d22452312"
        }
    }
}
```
* version.manifest example

```
{
    "packageUrl": "http://host:8080/update/files/",
    "remoteVersionUrl": "http://host:8080/update/version/version.manifest",
    "version": "1.20151115.1",
    "engineVersion": "Quick 3.5",
    "remoteManifestUrl": "http://host:8080/update/version/project.manifest"
}
```