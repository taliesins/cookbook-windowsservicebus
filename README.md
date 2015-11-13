# windowsservicebus-cookbook

Cookbook to install Windows Service Bus

## Supported Platforms

Windows

## Attributes

<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
    <td><tt>['windowsservicebus']['bacon']</tt></td>
    <td>Boolean</td>
    <td>whether to include bacon</td>
    <td><tt>true</tt></td>
  </tr>
</table>

## Usage

### windowsservicebus::default

Include `windowsservicebus` in your node's `run_list`:

```json
{
  "run_list": [
    "recipe[windowsservicebus::default]"
  ]
}
```

## License and Authors

Author:: YOUR_NAME (<YOUR_EMAIL>)
