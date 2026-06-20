import re

with open('c:/Ngam/lib/screens/shared/chat_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix the dangling brackets
dangling = '''
                ],
              ),
            ),
          ),
        );
  }
}'''
content = content.replace(dangling, '', 1)

# Append SwipeToReply
swipe_to_reply_code = '''
class SwipeToReply extends StatefulWidget {
  final Widget child;
  final VoidCallback onSwipe;
  final bool isMe;

  const SwipeToReply({
    super.key,
    required this.child,
    required this.onSwipe,
    required this.isMe,
  });

  @override
  State<SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<SwipeToReply> with SingleTickerProviderStateMixin {
  double _dragOffset = 0.0;
  final double _maxDrag = 60.0;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animationController.addListener(() {
      setState(() {
        _dragOffset = _animation.value;
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _resetDrag() {
    _animation = Tween<double>(begin: _dragOffset, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragUpdate: (details) {
        setState(() {
          _dragOffset += details.delta.dx;
          if (widget.isMe) {
            _dragOffset = _dragOffset.clamp(-_maxDrag, 0.0);
          } else {
            _dragOffset = _dragOffset.clamp(0.0, _maxDrag);
          }
        });
      },
      onHorizontalDragEnd: (details) {
        if (_dragOffset.abs() >= _maxDrag * 0.8) {
          widget.onSwipe();
        }
        _resetDrag();
      },
      onHorizontalDragCancel: () {
        _resetDrag();
      },
      child: Stack(
        alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
        children: [
          if (_dragOffset.abs() > 10)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Icon(
                Icons.reply_rounded,
                color: Colors.grey.withValues(alpha: (_dragOffset.abs() / _maxDrag).clamp(0.0, 1.0)),
              ),
            ),
          Transform.translate(
            offset: Offset(_dragOffset, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
'''
if 'class SwipeToReply' not in content:
    content += swipe_to_reply_code

with open('c:/Ngam/lib/screens/shared/chat_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
