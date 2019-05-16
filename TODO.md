## first release

- Publish Elm package
  - Get rid of File
  - Should we wrap Msg? -- probably yes (esp if this gets rid of `noOp`)
  - Make sure referenced types are exposed
  - `files` (or "userData"?) should be a Maybe
  - should there be an initial loading state?  does adding this change the API?
  - make sure README code is correct
- init requires an app-id (with wizard input?) (mngen)


## future

- API for handling data migrations
- store data remotely (gist?)
- packaged app has menu for opening alt file locations
