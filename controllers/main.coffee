

exports.default = (req, res, next) ->
    # status
    res.status 200

    # render
    res.render('platform',
        layout: 'layout'
    , (err, html) ->
        unless err
            # minify the html - beware, it stalls on certain html code -> disabled for now!
            unless true or serverConfig.debug
                html = minify html,
                    removeComments: true
                    collapseWhitespace: true
                    conservativeCollapse: true
                    preserveLineBreaks: true
                    removeEmptyAttributes: true

            # send it
            res.send html
        else
            next err
    )