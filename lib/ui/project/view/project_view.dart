import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:invoiceninja_flutter/data/models/models.dart';
import 'package:invoiceninja_flutter/ui/app/buttons/bottom_buttons.dart';
import 'package:invoiceninja_flutter/ui/app/view_scaffold.dart';
import 'package:invoiceninja_flutter/ui/project/view/project_view_documents.dart';
import 'package:invoiceninja_flutter/ui/project/view/project_view_overview.dart';
import 'package:invoiceninja_flutter/ui/project/view/project_view_vm.dart';
import 'package:invoiceninja_flutter/utils/localization.dart';

class ProjectView extends StatefulWidget {
  const ProjectView({
    Key key,
    @required this.viewModel,
    @required this.isFilter,
  }) : super(key: key);

  final ProjectViewVM viewModel;
  final bool isFilter;

  @override
  _ProjectViewState createState() => new _ProjectViewState();
}

class _ProjectViewState extends State<ProjectView>
    with SingleTickerProviderStateMixin {
  TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(vsync: this, length: 2);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;
    final state = viewModel.state;
    final project = viewModel.project;
    final localization = AppLocalization.of(context);
    final documents = project.documents;

    return ViewScaffold(
      isFilter: widget.isFilter,
      entity: project,
      appBarBottom: TabBar(
        controller: _controller,
        isScrollable: false,
        tabs: [
          Tab(
            text: localization.overview,
          ),
          Tab(
            text: documents.isEmpty
                ? localization.documents
                : '${localization.documents} (${documents.length})',
          ),
        ],
      ),
      body: Builder(builder: (context) {
        return Column(
          children: <Widget>[
            Expanded(
              child: TabBarView(
                controller: _controller,
                children: <Widget>[
                  RefreshIndicator(
                    onRefresh: () => viewModel.onRefreshed(context),
                    child: ProjectOverview(
                      viewModel: viewModel,
                      isFilter: widget.isFilter,
                    ),
                  ),
                  RefreshIndicator(
                    onRefresh: () => viewModel.onRefreshed(context),
                    child: ProjectViewDocuments(
                      viewModel: viewModel,
                      key: ValueKey(viewModel.project.id),
                    ),
                  ),
                ],
              ),
            ),
            BottomButtons(
              entity: project,
              action1: EntityAction.newTask,
              action2: state.company.isModuleEnabled(EntityType.expense)
                  ? EntityAction.newExpense
                  : EntityAction.newInvoice,
            ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        heroTag: 'project_view_fab',
        backgroundColor: Theme.of(context).primaryColorDark,
        onPressed: () => viewModel.onAddTaskPressed(context),
        child: Icon(
          Icons.add,
          color: Colors.white,
        ),
        tooltip: localization.newTask,
      ),
    );
  }
}
