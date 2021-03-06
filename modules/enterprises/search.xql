xquery version "1.0";
(: --------------------------------------
   Case tracker pilote

   Creation: Stéphane Sire <s.sire@oppidoc.fr>

   Brings up enterprises search page with default search submission results
   or execute a search submission (POST) to return an HTML fragment.
   
   FIXME: 
   - return 200 instead of 201 when AXEL-FORM will have been changed
   - MODIFIER button iff site-admin user (?)

   May 2013 - (c) Copyright 2013 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)

import module namespace request="http://exist-db.org/xquery/request";

import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../../oppidum/lib/util.xqm";
import module namespace search = "http://oppidoc.com/ns/xcm/search" at "search.xqm";
import module namespace submission = "http://oppidoc.com/ns/xcm/submission" at "../submission/submission.xqm";
import module namespace access = "http://oppidoc.com/ns/xcm/access" at "../../lib/access.xqm";

declare option exist:serialize "method=xml media-type=text/xml";

let $m := request:get-method()
return
  if ($m eq 'POST') then (: executes search requests :)
    let $request := oppidum:get-data()
    return
      <Search>
        {
        search:fetch-enterprises($request)
        }
      </Search>
  else (: shows search page with default results - assumes GET :)
    let $preview := request:get-parameter('preview', ())
    let $can-create := access:check-user-can('create', 'Enterprise')
    return
      <Search Initial="true">
        <Formular Id="editor" Width="680px">
          <Template loc="form.title.enterprises.search">templates/search/enterprises</Template>
          {
          if (not($preview)) then
            <Submission Controller="enterprises">enterprises/submission</Submission>
          else
            ()
          }
          <Commands>
            {
            if ($can-create) then
              <Create Target="c-item-creator">
                <Controller>enterprises/add?next=redirect</Controller>
                <Label loc="action.add.enterprise">Ajouter</Label>
              </Create>
            else
              ()
            }
            <Save Target="editor" data-src="enterprises" data-replace-target="results" data-save-flags="disableOnSave silentErrors" onclick="javascript:$('#c-busy').show()">
              <Label style="min-width: 150px" loc="action.search">Search</Label>
            </Save>
          </Commands>
        </Formular>
        {
        if ($preview) then
          (: simulates a search targeted at a single enterprise :)
          search:fetch-enterprises(
            <SearchEnterprisesRequest>
              <Enterprises>
                <EnterpriseRef>{$preview}</EnterpriseRef>
              </Enterprises>
            </SearchEnterprisesRequest>
          )
        else
          let $saved-request := submission:get-default-request('SearchEnterprisesRequest')
          return
            if (local-name($saved-request) = local-name($submission:empty-req)) then
              <NoRequest/>
            else
              search:fetch-enterprises($saved-request)
        }
        <Modals>
          <Modal Id="c-item-viewer" Goal="read">
            <Template>templates/enterprise?goal=read</Template>
            <Commands>
              {
              if (access:check-user-can('delete', 'Enterprise')) then
                <Delete/>
              else
                ()
              }
              <Button Id="c-modify-btn" loc="action.edit"/>
              <Close/>
            </Commands>
          </Modal>
          <Modal Id="c-item-editor" data-backdrop="static" data-keyboard="false">
            <Template>templates/enterprise?goal=update</Template>
            <Commands>
              <Save/>
              <Cancel/>
            </Commands>
          </Modal>
          {
          if ($can-create) then
            <Modal Id="c-item-creator" data-backdrop="static" data-keyboard="false">
              <Name>Add a new company</Name>
              <Template>templates/enterprise?goal=create</Template>
              <Commands>
                <Save/>
                <Cancel/>
                <Clear/>
              </Commands>
            </Modal>
          else
            ()
          }
        </Modals>
      </Search>
